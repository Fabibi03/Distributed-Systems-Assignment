import ballerina/grpc;
import ballerina/io;

// Main function
public function main() returns error? {
    // Create a client for the Car Rental gRPC service
    carrental:CarRentalServiceClient client = check new("http://localhost:9090");

    //Add a car
    var addCarResponse = client->add_car({
        car: {
            plate: "N1234W",
            make: "Honda",
            model: "Fit",
            year: 2019,
            daily_price: 40.0,
            mileage: 63748,
            status: "AVAILABLE"
        }
    });

    if addCarResponse is error {
        io:println("Error adding car: ", addCarResponse.message());
    } else {
        io:println("Car added: ", addCarResponse.plate);
    }

    //Create users
    stream<carrental:User> users = new;
    var createUsersResponse = client->create_users(users);

    // Send user data
    check users.send({ username: "Fabs", role: "customer" });
    check users.send({ username: "admin1", role: "admin" });

    // Tell the server we are done sending users
    check users.complete();

    if createUsersResponse is error {
        io:println("Error creating users: ", createUsersResponse.message());
    } else {
        io:println("Users created successfully!");
    }

    //List available cars
    stream<carrental:Car> cars = check client->list_available_cars({ filter: "" });
    io:println("Available cars:");

    // Read each car from the stream
    while true {
        var carResult = cars.next();
        if carResult is carrental:Car {
            io:println(carResult.plate, " - ", carResult.make, " ", carResult.model);
        } else {
            break;
        }
    }

    //Add a car to the cart
    var addToCartResponse = client->add_to_cart({
        username: "Fabs",
        plate: "N1234W",
        start_date: "2023-06-01",
        end_date: "2023-06-05"
    });

    if addToCartResponse is error {
        io:println("Error adding to cart: ", addToCartResponse.message());
    } else {
        io:println("Added to cart successfully!");
    }

    //Make a reservation
    var reservationResponse = client->place_reservation({ username: "john" });

    if reservationResponse is error {
        io:println("Error placing reservation: ", reservationResponse.message());
    } else {
        io:println("Reservation placed successfully!");
        foreach var res in reservationResponse.reservations {
            io:println("Reserved car: ", res.car.plate, 
                       " from ", res.start_date, 
                       " to ", res.end_date);
        }
    }
}
