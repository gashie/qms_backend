const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.CreateServiceFields = asynHandler(async (req, res, next) => {
    let items = req.body.form_fields;
    let { service_id } = req.body
    let itemCount = items.length;
    /**
 * Create new role.
 * @param {string} name - Name or title of the .
 * @param {string} description - Description: for risk management.
 * @returns {Object} - Object containing role details.
 */

    let isDone = false
    for (const item of items) {
        item.service_id = service_id

        console.log(item);
        await GlobalModel.Create(item, 'form_fields', '');
        if (!--itemCount) {
            isDone = true;
            console.log(" => This is the last iteration...");

        } else {
            console.log(" => Still saving data...");

        }
    }
    if (isDone) {
        return sendResponse(res, 1, 200, `${items.length} new fields added to service with id ${service_id}`, { service_id, items })
    }

})



exports.SearchServicesFields = asynHandler(async (req, res, next) => {
    let { service_id } = req.body
    const tableName = 'form_fields';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'service_id', operator: '=', value: service_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateServiceFields = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'form_fields', 'field_id', payload.field_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})
