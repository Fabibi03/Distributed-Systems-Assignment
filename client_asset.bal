import ballerina/http;
import ballerina/log;

// URL of the asset management service
string baseUrl = "http://localhost:8080/assets";

// Create HTTP client
http:Client assetClient = check new(baseUrl);

public function main() returns error? {
    //Create an asset
    json newAsset = {
        assetTag: "Pasop123",
        name: "Printer",
        faculty: "Computing & Informatics",
        department: "Software Engineering",
        status: "ACTIVE",
        dateAcquired: "2024-03-10",
        components: [],
        schedules: [],
        workOrders: [],
    };

    var createResp = assetClient->post("/", newAsset);
    if (createResp is http:Response) {
        json body = check createResp.getJsonPayload();
        log:printInfo("Asset created: " + body.toJsonString());
    } else {
        log:printError("Failed to create asset", createResp);
    }

Update the asset
    json updatedAsset = {
        assetTag: "Pasop123",
        name: "Printer - Updated",
        faculty: "Computing & Informatics",
        department: "Software Engineering",
        status: "UNDER_REPAIR",
        dateAcquired: "2024-03-10",
        components: [],
        schedules: [],
        workOrders: [],
    };

    var updateResp = assetClient->put("/Pasop123", updatedAsset);
    if (updateResp is http:Response) {
        json body = check updateResp.getJsonPayload();
        log:printInfo("Asset updated: " + body.toJsonString());
    } else {
        log:printError("Failed to update asset", updateResp);
    }

    
    //View all assets
    var allResp = assetClient->get("/");
    if (allResp is http:Response) {
        json body = check allResp.getJsonPayload();
        log:printInfo("All assets: " + body.toJsonString());
    } else {
        log:printError("Failed to get all assets", allResp);
    }

   
    //View assets by faculty
    var facultyResp = assetClient->get("/faculty/Computing & Informatics");
    if (facultyResp is http:Response) {
        json body = check facultyResp.getJsonPayload();
        log:printInfo("Assets by faculty: " + body.toJsonString());
    } else {
        log:printError("Failed to get assets by faculty", facultyResp);
    }

    //Add a component
    json newComponent = {
        id: "Pasop111",
        name: "Personal Computer"
    };

    var compResp = assetClient->post("/EQ-001/components", newComponent);
    if (compResp is http:Response) {
        json body = check compResp.getJsonPayload();
        log:printInfo("Component added: " + body.toJsonString());
    } else {
        log:printError("Failed to add component", compResp);
    }

    //Add a maintenance schedule
    json newSchedule = {
        id: "S1",
        frequency: "yearly",
        nextDue: "2025-09-01"
    };

    var schedResp = assetClient->post("/Pasop123/schedules", newSchedule);
    if (schedResp is http:Response) {
        json body = check schedResp.getJsonPayload();
        log:printInfo("Schedule added: " + body.toJsonString());
    } else {
        log:printError("Failed to add schedule", schedResp);
    }
}
