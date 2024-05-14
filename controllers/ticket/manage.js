const asynHandler = require("../../middleware/async");
const licenseKey = require('license-key-gen');
const customId = require("custom-id");
const path = require("path");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { GenerateTicket } = require("../../model/Ticket");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.GenerateNewTicket = asynHandler(async (req, res, next) => {

let {branch_acronym,branch_id,service_id,customer_id,status,dispenser_id,form_id} = req.body
    /**
 * Create new company.
 * @param {string} name - Name or title of the branch.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing branch details.
 */
    let refresult = await GenerateTicket(branch_acronym,branch_id,service_id,customer_id,status,dispenser_id,form_id);
    res.send(refresult.rows[0])

  
    // let payload = req.body;
    // let authentication_code = customId({
    //     name: payload.name, // Optional
    //     randomLength: 2, // Optional,
    //     uniqueId: 4563, // Optional // You can provide any number
    //     lowerCase: false // Optional
    // });
    // payload.authentication_code = authentication_code
    // if (payload?.device_type === 'display') {
    //     payload.activation_status = 'active'
    //     payload.is_activated = true
    // } else {

    //     payload.activation_status = 'pending'
    // }
    // let results = await GlobalModel.Create(payload, 'devices', '');
    // if (results.rowCount == 1) {
    //     return sendResponse(res, 1, 200, "Record saved", { status: payload.activation_status, authentication_code })
    // } else {
    //     return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    // }

})

