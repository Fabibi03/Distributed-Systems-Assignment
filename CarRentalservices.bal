import ballerina/grpc;
import ballerina/io;

// Simple types for Car, User, CartItem, Reservation
type Car record {
    string plate;
    string make;
    string model;
    int year;
    float dailyPrice;
    int mileage;
    string status; // "AVAILABLE" or "UNAVAILABLE"
};

type User record {
    string username;
    string role; // "customer" or "admin"
};

type CartItem record {
    string plate;
    string startDate;
    string endDate;
};

type Reservation record {
    string username;
    Car car;
    string startDate;
    string endDate;
    float totalPrice;
};

// Car Rental Service
service class CarRentalService extends grpc:Service {

    // Store data in memory
    map<Car> cars = {};
    map<User> users = {};
    map<CartItem[]> carts = {};
    Reservation[] reservations = [];

    // Add a car
    remote function add_car(carrental:AddCarRequest req) returns carrental:AddCarResponse|error {
        if cars.hasKey(req.car.plate) {
            return error("Car already exists");
        }
        cars[req.car.plate] = {
            plate: req.car.plate,
            make: req.car.make,
            model: req.car.model,
            year: req.car.year,
            dailyPrice: req.car.daily_price,
            mileage: req.car.mileage,
            status: req.car.status
        };
        return { plate: req.car.plate };
    }

    // Create users from stream
    remote function create_users(stream<carrental:User > userStream) returns carrental:CreateUsersResponse|error {
        while true {
            var user = userStream.next();
            if user is carrental:User  {
                users[user.username] = { username: user.username, role: user.role };
            } else {
                break;
            }
        }
        return { message: "Users created" };
    }

    // List available cars
    remote function list_available_cars(carrental:ListAvailableCarsRequest req) returns stream<carrental:Car>|error {
        stream<carrental:Car> carStream = new;
        foreach var [_, car] in cars.entries() {
            if car.status == "AVAILABLE" {
                check carStream.send({
                    plate: car.plate,
                    make: car.make,
                    model: car.model,
                    year: car.year,
                    daily_price: car.dailyPrice,
                    mileage: car.mileage,
                    status: car.status
                });
            }
        }
        check carStream.complete();
        return carStream;
    }

    // Add to cart
    remote function add_to_cart(carrental:AddToCartRequest req) returns carrental:AddToCartResponse|error {
        if !users.hasKey(req.username) {
            return { success: false, message: "User  not found" };
        }
        if !cars.hasKey(req.plate) {
            return { success: false, message: "Car not found" };
        }
        CartItem item = { plate: req.plate, startDate: req.start_date, endDate: req.end_date };
        if carts.hasKey(req.username) {
            carts[req.username].push(item);
        } else {
            carts[req.username] = [item];
        }
        return { success: true, message: "Added to cart" };
    }

    // Place reservation
    remote function place_reservation(carrental:PlaceReservationRequest req) returns carrental:PlaceReservationResponse|error {
        if !carts.hasKey(req.username) {
            return { message: "Cart is empty", reservations: [] };
        }

        CartItem[] userCart = carts[req.username];
        Reservation[] confirmed = [];

        foreach var item in userCart {
            Car car = cars[item.plate];
            int days = calculateDays(item.startDate, item.endDate);
            Reservation res = {
                username: req.username,
                car: car,
                startDate: item.startDate,
                endDate: item.endDate,
                totalPrice: days * car.dailyPrice
            };
            reservations.push(res);
            confirmed.push(res);
        }

        carts.remove(req.username);
        return { message: "Reservation placed", reservations: confirmed };
    }

    // List all reservations
    remote function list_reservations(google.protobuf.Empty req) returns carrental:ListReservationsResponse|error {
        return { reservations: reservations };
    }
}

// Helper function to calculate days between two dates
function calculateDays(string start, string end) returns int {
    string[] startParts = start.split("-");
    string[] endParts = end.split("-");
    int startDay = checkpanic int:fromString(startParts[2]);
    int endDay = checkpanic int:fromString(endParts[2]);
    return endDay - startDay;
}

// Main function to start the server
public function main() returns error? {
    grpc:Server server = new(9090);
    check server.attach(new CarRentalService());
    io:println("Server started on port 9090");
    check server.start();
}