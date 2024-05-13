// In autoCreateEnrollment.js
const GlobalModel = require("../model/Global");
const { ShowMyDeviceTemplates } = require("../model/Templates");
const { sendResponse, CatchHistory, sendCookie } = require("./utilfunc");
const { SimpleEncrypt, SimpleDecrypt } = require("./utilfunc");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");
const autoGenerateCookie = async (req, res, next,userIp) => {

    // Function implementation
    let { device_id } = req.body
    let showdevicetemplate = await ShowMyDeviceTemplates(userIp);
    if (showdevicetemplate.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Template found for this device", [])
    }
    let template = showdevicetemplate.rows[0]

    sendCookie(template, 1, 200, res, req);
    // Call next middleware
    req.device_template = template;
    return next();
};

module.exports = { autoGenerateCookie };
