const asynHandler = require("../../middleware/async");
const licenseKey = require('license-key-gen');
const customId = require("custom-id");
const path = require("path");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { SimpleEncrypt } = require("../../helper/devicefuncs");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.RegisterDevice = asynHandler(async (req, res, next) => {
    /**
 * Create new company.
 * @param {string} name - Name or title of the branch.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing branch details.
 */

    let payload = req.body;
    let authentication_code = customId({
        name: payload.name, // Optional
        randomLength: 2, // Optional,
        uniqueId: 4563, // Optional // You can provide any number
        lowerCase: false // Optional
    });
    payload.authentication_code = authentication_code
    if (payload?.device_type === 'display') {
        payload.activation_status = 'active'
        payload.is_activated = true
    } else {

        payload.activation_status = 'pending'
    }
    let results = await GlobalModel.Create(payload, 'devices', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", { status: payload.activation_status, authentication_code })
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.ActivateDevice = asynHandler(async (req, res, next) => {
    let { authentication_code, device_info } = req.body
    let payload = {};
    const tableName = 'devices';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'authentication_code', operator: '=', value: authentication_code },
        { column: 'is_activated', operator: '=', value: false },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    // device_info.authentication_code = authentication_code
    var licenseData = { info: device_info, prodCode: "LEN100120", appVersion: "1.5", osType: 'IOS8' }
    var license_key = licenseKey.createLicense(licenseData)
    let token = SimpleEncrypt(license_key.license, device_info.mac)
    payload.license_key = token
    payload.is_activated = true
    payload.activation_status = 'activated'
    payload.updated_at = systemDate
    payload.activated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'devices', 'device_id', results.rows[0].device_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", { license: license_key.license, status: payload.activation_status, activated_at: payload.activated_at, authentication_code })


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }

})

exports.ViewRegisteredDevices = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'dispenser_templates';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    let template_id = results.rows[0].template_id
    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.ViewDevices = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'devices';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateDevices = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'devices', 'device_id', payload.device_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})



exports.UpdateRegisteredDevices = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'dispenser_templates', 'template_id', payload.template_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

