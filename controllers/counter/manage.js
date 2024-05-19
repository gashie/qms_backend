const asynHandler = require("../../middleware/async");
const voucher_codes = require('voucher-code-generator');
const { sendResponse, CatchHistory, sendCounterCookie } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { counterServices, counterDevices } = require("../../model/Counter");
const { DetectIp } = require("../../helper/devicefuncs");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.SetupCounter = asynHandler(async (req, res, next) => {
    /**
 * Create new company.
 * @param {string} name - Name or title of the branch.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing branch details.
 */

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'counter', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.ViewCounters = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'counter';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateCounter = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'counter', 'counter_id', payload.counter_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

exports.AssignServiceToCounter = asynHandler(async (req, res, next) => {
    /**

 */

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'service_counter_assignment', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})
exports.ViewCounterServices = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    let results = await counterServices();
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    sendResponse(res, 1, 200, "Record Found", results.rows)
})


exports.UpdateCounterServices = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'service_counter_assignment', 'service_counter_assignment_id', payload.service_counter_assignment_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

exports.RegisterCounterStation = asynHandler(async (req, res, next) => {
    let payload = req.body;
    /**
 * Create new company.
 * @param {string} name - Name or title of the branch.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing branch details.
 */
    // Find template carousel
    const tableNameOne = 'counter';
    const columnsToSelectTwo = []; // Use string values for column names
    const conditionsTwo = [
        { column: 'counter_id', operator: '=', value: payload.counter_id },
    ];
    let counter = await GlobalModel.Finder(tableNameOne, columnsToSelectTwo, conditionsTwo)
    if (counter.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, Counter this counter does not exist", [])
    }
    // Find assigned counter
    const tableName = 'counter_assignments';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
        { column: 'counter_id', operator: '=', value: payload.counter_id },
    ];
    let counter_station = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (counter_station.rows.length > 0) {
        return sendResponse(res, 0, 200, "Sorry, Counter has already been assigned", [])
    }


    let counterInfo = counter.rows[0];
    let code = voucher_codes.generate({
        prefix: "CT-",
        postfix: `-${payload?.name}`,
        length: 6,
        count: 1,
        charset: '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    });
    
    let devicePayload = {
        branch_id: counterInfo.branch_id,
        device_name: payload.name,
        device_type: 'counter_station_device',
        authentication_code: code[0],
        activation_status: 'pending'
    }

    let results = await GlobalModel.Create(devicePayload, 'devices', ''); //save device information, set status to pending with auth code
    if (results.rowCount == 1) {
        //after creating the device, assign the device to the counter
        let assignPayload = {
            counter_id: payload.counter_id,
            branch_id: devicePayload.branch_id,
            device_id: results.rows[0].device_id
        }
        await GlobalModel.Create(assignPayload, 'counter_assignments', '');
        return sendResponse(res, 1, 200, "Record saved", { status: devicePayload.activation_status, authentication_code: devicePayload.authentication_code })
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})
exports.ActivateCounterStation = asynHandler(async (req, res, next) => {
    let { authentication_code } = req.body
    let payload = {};
    const tableName = 'devices';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'authentication_code', operator: '=', value: authentication_code },
        { column: 'is_activated', operator: '=', value: false },
        { column: 'activation_status', operator: '=', value: 'pending' },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    payload.ip_address =  DetectIp(req);
    payload.is_activated = true
    payload.activation_status = 'activated'
    payload.updated_at = systemDate
    payload.activated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'devices', 'device_id', results.rows[0].device_id)
    if (runupdate.rowCount == 1) {
       let counter_object = {
        authentication_code:authentication_code,
        ip_address:payload.ip_address,
        is_activated:payload.is_activated
       }
        return sendCounterCookie(counter_object, 1, 200, res, req)


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }

})

exports.ViewCounterStationDevices = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    let results = await counterDevices();
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    sendResponse(res, 1, 200, "Record Found", results.rows)
})
