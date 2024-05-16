// In autoCreateEnrollment.js
const GlobalModel = require("../model/Global");
const licenseKey = require('license-key-gen');
const { ShowMyDeviceTemplates } = require("../model/Templates");
const { sendResponse, CatchHistory, sendCookie } = require("./utilfunc");
const { SimpleDecrypt } = require("../helper/devicefuncs");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");
const autoGenerateCookie = async (req, res, next, userIp) => {

    // Function implementation
    let { device_info, license, mac } = req.headers
    console.log('====================================');
    console.log(mac);
    console.log('====================================');
    if (license) {
        //decrypt license and check if it match the one in the db, if yes,
        // Search for user in db
        const tableName = "devices";
        const columnsToSelect = []; // Use string values for column names
        const conditions = [{ column: "device_mac", operator: "=", value: mac }];
        let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions);
        let DeviceDbInfo = results.rows[0];

        if (!DeviceDbInfo) {
            //device mac not in db
            return sendResponse(res, 0, 401, "Unauthorized access, mac not found");
        }
        //----check device activation too

        //validate lince 
        let token = SimpleDecrypt(DeviceDbInfo.license_key, mac);
        if (token !== license) {
            //licensense does not match
            return sendResponse(res, 0, 401, "Unauthorized access");
        }

        try {
            //validate license against device info
            var licenseData = { info: JSON.parse(device_info), prodCode: "LEN100120", appVersion: "1.5", osType: 'IOS8' }
            var license_key = licenseKey.validateLicense(licenseData, license)
            if (license_key.message !== 'ok') {
                //licensense does not match
                return sendResponse(res, 0, 401, "Unauthorized access");
            }
        } catch (error) {
            if (error.errorCode === 1006) {
                //licensense does not match
                return sendResponse(res, 0, 401, error.message);
            }
        }

        let showdevicetemplate = await ShowMyDeviceTemplates(mac);
        if (showdevicetemplate.rows.length == 0) {
            return sendResponse(res, 0, 200, "Sorry, No Template found for this device", [])
        }
        let template = showdevicetemplate.rows[0]

        sendCookie(template, 1, 200, res, req);
        // Call next middleware
        req.device_template = template;
        return next();
    } else {
        //for display tv
        let showdevicetemplate = await ShowMyDeviceTemplates(userIp);
        if (showdevicetemplate.rows.length == 0) {
            return sendResponse(res, 0, 200, "Sorry, No Template found for this device", [])
        }
        let template = showdevicetemplate.rows[0]

        sendCookie(template, 1, 200, res, req);
        // Call next middleware
        req.device_template = template;
        return next();
    }
};

module.exports = { autoGenerateCookie };
