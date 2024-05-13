const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.SetupService = asynHandler(async (req, res, next) => {
    /**
 * Create new company.
 * @param {string} name - Name or title of the branch.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing branch details.
 */

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'service', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.ViewServices = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'service';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.SearchServices = asynHandler(async (req, res, next) => {
    let { branch_id,service_id } = req.body
    const tableName = 'service';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'parent_service_id', operator: '=', value: service_id },
    ];
    const BranchConditions = [
        { column: 'branch_id', operator: '=', value: branch_id },
        { column: 'parent_service_id', operator: 'IS', value: null },

        
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, branch_id ? BranchConditions :ServiceConditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateService = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'service', 'service_id', payload.service_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})
