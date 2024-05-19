const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { FindServiceForm, ListServiceForms } = require("../../model/Forms");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.AssignServiceToForm = asynHandler(async (req, res, next) => {
    // let {service_id,form_id} = req.body
    /**
 * Link service to  form.
 * @param {string} form_id - Name or title of the form.
 */

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'service_form_mapping', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})




exports.SearchServicesFields = asynHandler(async (req, res, next) => {
    let { service_id } = req.body



    let findform = await FindServiceForm(service_id);
    if (findform.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
 
    // const tableName = 'form_fields';
    // const columnsToSelect = []; // Use string values for column names
    // const ServiceConditions = [
    //     { column: 'form_id', operator: '=', value: findform.rows[0].form_id },
    // ];
    // let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)
    

    // sendResponse(res, 1, 200, "Record Found", {form:findform.rows[0],form_fields:results.rows})
    sendResponse(res, 1, 200, "Record Found", findform.rows)
})

exports.ViewServiceForms = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    let results = await ListServiceForms();
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateServiceFields = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'service_form_mapping', 'mapping_id', payload.mapping_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})
