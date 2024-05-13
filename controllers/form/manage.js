const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.SetupForm = asynHandler(async (req, res, next) => {
    /**
 * Create new form.
 * @param {string} name - Name or title of the form.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing form details.
 */

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'forms', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.ViewForms = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'forms';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})



exports.UpdateForm = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'forms', 'form_id', payload.form_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

/**
* Setup form fields.
* */

exports.SetupFormFields = asynHandler(async (req, res, next) => {
    /**
 * Create new form fields.
 * @param {string} form_id - Name or title of the branch.
 * @returns {Object} - Object containing fields details.
 */



    let items = req.body.form_fields;
    let { form_id } = req.body
    let itemCount = items.length;
    /**
 * Create new role.
 * @param {string} name - Name or title of the .
 * @param {string} description - Description: for risk management.
 * @returns {Object} - Object containing role details.
 */

    let isDone = false
    for (const item of items) {
        item.form_id = form_id

        await GlobalModel.Create(item, 'form_fields', '');
        if (!--itemCount) {
            isDone = true;
            console.log(" => This is the last iteration...");

        } else {
            console.log(" => Still saving data...");

        }
    }
    if (isDone) {
        return sendResponse(res, 1, 200, `${items.length} new fields added to form with id ${form_id}`, { form_id, items })
    }

})

exports.SearchFormFields = asynHandler(async (req, res, next) => {
    let { form_id } = req.body
    const tableName = 'form_fields';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'form_id', operator: '=', value: form_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateFormFields = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'form_fields', 'field_id', payload.field_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})