import ballerina/http;
import ballerina/log;
import ballerina/time;

public type Status string;

public type Component record {|
    string id;
    string name;
    string? description;
|};

public type Schedule record {|
    string id;
    string frequency;
    string nextDue;
|};

public type Task record {|
    string id;
    string description;
    boolean done = false;
|};

public type WorkOrder record {|
    string id;
    string description;
    string status;
    Task[] tasks = [];
    string openedAt;
    string? closedAt;
|};

public type Asset record {|
    string assetTag;
    string name;
    string faculty;
    string department;
    string dateAcquired;
    Status status = "ACTIVE";
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};

map<Asset> assets = {};

listener http:Listener listenerEndpoint = new (8080);

service /assets on listenerEndpoint {

    // CREATE ASSET
    resource function post . (http:Request req) returns json|error {
        json requestBody = check req.getJsonPayload();
        Asset newAsset = check requestBody.cloneWithType(Asset);

        if (assets.hasKey(newAsset.assetTag)) {
            return respondWithError(409, "Asset with this tag already exists");
        }

        assets[newAsset.assetTag] = newAsset;
        return { "status": 201, "asset": newAsset };
    }

    // GET ALL ASSETS
    resource function get . () returns json {
        Asset[] allAssets = [];
        foreach var [_, asset] in assets.entries() {
            allAssets.push(asset);
        }
        return allAssets;
    }

    // GET ASSETS BY FACULTY
    resource function get faculty/[string facultyName]() returns json {
        Asset[] facultyAssets = [];
        foreach var [_, asset] in assets.entries() {
            if (asset.faculty == facultyName) {
                facultyAssets.push(asset);
            }
        }
        return facultyAssets;
    }

    // GET OVERDUE SCHEDULES
    resource function get overdue() returns json {
        string today = getTodayString();
        Asset[] overdueAssets = [];

        foreach var [_, asset] in assets.entries() {
            boolean hasOverdueSchedule = false;
            foreach var schedule in asset.schedules {
                if (schedule.nextDue <= today) {
                    hasOverdueSchedule = true;
                    break; 
                }
            }
            if (hasOverdueSchedule) {
                overdueAssets.push(asset);
            }
        }
        return overdueAssets;
    }

    // GET SINGLE ASSET
    resource function get [string assetTag]() returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }
        return assets.get(assetTag);
    }

    // UPDATE ASSET
    resource function put [string assetTag](http:Request req) returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        json requestBody = check req.getJsonPayload();
        Asset updatedAsset = check requestBody.cloneWithType(Asset);

        if (updatedAsset.assetTag != assetTag) {
            return respondWithError(400, "assetTag mismatch in URL and body");
        }

        assets[assetTag] = updatedAsset;
        return updatedAsset;
    }

    // DELETE ASSET
    resource function 'delete [string assetTag]() returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        _ = assets.remove(assetTag);
        return { "status": 200, "message": "deleted" };
    }

    // ADD COMPONENT
    resource function post [string assetTag]/components (http:Request req) returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        Component newComponent = check req.getJsonPayload().cloneWithType(Component);
        assets.get(assetTag).components.push(newComponent);
        return assets.get(assetTag);
    }

    // DELETE COMPONENT
    resource function 'delete [string assetTag]/components/[string compId]() returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        Component[] remainingComponents = [];
        boolean componentWasRemoved = false;

        foreach var component in assets.get(assetTag).components {
            if (component.id != compId) {
                remainingComponents.push(component);
            } else {
                componentWasRemoved = true;
            }
        }

        if (!componentWasRemoved) {
            return respondWithError(404, "Component not found");
        }

        assets.get(assetTag).components = remainingComponents;
        return assets.get(assetTag);
    }

    // ADD SCHEDULE
    resource function post [string assetTag]/schedules (http:Request req) returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        Schedule newSchedule = check req.getJsonPayload().cloneWithType(Schedule);
        assets.get(assetTag).schedules.push(newSchedule);
        return assets.get(assetTag);
    }

    // DELETE SCHEDULE
    resource function 'delete [string assetTag]/schedules/[string schId]() returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        Schedule[] remainingSchedules = [];
        boolean scheduleWasRemoved = false;

        foreach var schedule in assets.get(assetTag).schedules {
            if (schedule.id != schId) {
                remainingSchedules.push(schedule);
            } else {
                scheduleWasRemoved = true;
            }
        }

        if (!scheduleWasRemoved) {
            return respondWithError(404, "Schedule not found");
        }

        assets.get(assetTag).schedules = remainingSchedules;
        return assets.get(assetTag);
    }

    // CREATE WORK ORDER
    resource function post [string assetTag]/workorders (http:Request req) returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        WorkOrder newWorkOrder = check req.getJsonPayload().cloneWithType(WorkOrder);
        assets.get(assetTag).workOrders.push(newWorkOrder);
        return assets.get(assetTag);
    }

    // UPDATE WORK ORDER
    resource function put [string assetTag]/workorders/[string woId] (http:Request req) returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        WorkOrder updatedWorkOrder = check req.getJsonPayload().cloneWithType(WorkOrder);
        WorkOrder[] updatedWorkOrders = [];
        boolean workOrderWasFound = false;

        foreach var workOrder in assets.get(assetTag).workOrders {
            if (workOrder.id == woId) {
                updatedWorkOrders.push(updatedWorkOrder);
                workOrderWasFound = true;
            } else {
                updatedWorkOrders.push(workOrder);
            }
        }

        if (!workOrderWasFound) {
            return respondWithError(404, "Work order not found");
        }

        assets.get(assetTag).workOrders = updatedWorkOrders;
        return assets.get(assetTag);
    }

    // DELETE WORK ORDER
    resource function 'delete [string assetTag]/workorders/[string woId]() returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        WorkOrder[] remainingWorkOrders = [];
        boolean workOrderWasRemoved = false;

        foreach var workOrder in assets.get(assetTag).workOrders {
            if (workOrder.id != woId) {
                remainingWorkOrders.push(workOrder);
            } else {
                workOrderWasRemoved = true;
            }
        }

        if (!workOrderWasRemoved) {
            return respondWithError(404, "Work order not found");
        }

        assets.get(assetTag).workOrders = remainingWorkOrders;
        return assets.get(assetTag);
    }

    // ADD TASK TO WORK ORDER
    resource function post [string assetTag]/workorders/[string woId]/tasks (http:Request req) returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        Task newTask = check req.getJsonPayload().cloneWithType(Task);
        boolean workOrderWasFound = false;

        foreach var workOrder in assets.get(assetTag).workOrders {
            if (workOrder.id == woId) {
                workOrder.tasks.push(newTask);
                workOrderWasFound = true;
                break; 
            }
        }

        if (!workOrderWasFound) {
            return respondWithError(404, "Work order not found");
        }

        return assets.get(assetTag);
    }

    // DELETE TASK FROM WORK ORDER
    resource function 'delete [string assetTag]/workorders/[string woId]/tasks/[string taskId]() returns json|error {
        if (!assets.hasKey(assetTag)) {
            return respondWithError(404, "Asset not found");
        }

        boolean workOrderWasFound = false;
        boolean taskWasRemoved = false;

        foreach var workOrder in assets.get(assetTag).workOrders {
            if (workOrder.id == woId) {
                workOrderWasFound = true;
                Task[] remainingTasks = [];
                foreach var task in workOrder.tasks {
                    if (task.id != taskId) {
                        remainingTasks.push(task);
                    } else {
                        taskWasRemoved = true;
                    }
                }
                workOrder.tasks = remainingTasks;
                break; 
            }
        }

        if (!workOrderWasFound) {
            return respondWithError(404, "Work order not found");
        }

        if (!taskWasRemoved) {
            return respondWithError(404, "Task not found");
        }

        return assets.get(assetTag);
    }
}

// Helper: Always return JSON for errors
function respondWithError(int statusCode, string message) returns json {
    return { "status": statusCode, "error": message };
}

// Helper: Get today’s date as YYYY-MM-DD
function getTodayString() returns string {
    time:Civil t = time:utcNow();
    return string `${t.year}-${t.month.toString().padStart(2, "0")}-${t.day.toString().padStart(2, "0")}`;
}

public function main() returns error? {
    log:printInfo("🚀 Asset Management API started at http://localhost:8080/assets");
}
