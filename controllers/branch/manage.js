const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.SetupCompany = asynHandler(async (req, res, next) => {
    /**
 * Create new company.
 * @param {string} name - Name or title of the company.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing company details.
 */

    //first find a company, if no company exist, proceed..
    const tableName = 'company';
    const columnsToSelect = [];
    const conditions = [
    ];
    let findExistingCompany = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (findExistingCompany.rows.length > 0) {
        return sendResponse(res, 0, 200, "Sorry, you have already setup a company", [])
    } else {
        let payload = req.body;
        let results = await GlobalModel.Create(payload, 'company', '');
        if (results.rowCount == 1) {
            return sendResponse(res, 1, 200, "Record saved", [])
        } else {
            return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

        }
    }

})

exports.ViewCompany = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'company';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateCompany = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'company', 'company_id', payload.company_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

/**
 * app versions

 */


exports.CreateAppVersions = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'application_versions', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.FindAppVersions = asynHandler(async (req, res, next) => {
    let { application_id } = req.body
    const tableName = 'application_versions';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
        { column: 'application_id', operator: '=', value: application_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateAppVersion = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'application_versions', 'version_id', payload.version_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

/**
 * app configuration templates

 */


exports.CreateAppConfigurations = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'application_config_templates', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.FindAppConfigurations = asynHandler(async (req, res, next) => {
    let { application_id } = req.body
    const tableName = 'application_config_templates';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
        { column: 'application_id', operator: '=', value: application_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows[0])
})

exports.UpdateAppConfigurations = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'application_config_templates', 'template_id', payload.template_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

/**
 * app  roles

 */


exports.CreateAppRoles = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'application_roles', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.FindAppRoles = asynHandler(async (req, res, next) => {
    let { application_id } = req.body
    const tableName = 'application_roles';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
        { column: 'application_id', operator: '=', value: application_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows[0])
})

exports.UpdateAppRoles = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'application_roles', 'role_id', payload.role_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})


/**
 * app  permissions

 */


exports.CreateAppPermissions = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'application_permissions', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.FindAppPermissions = asynHandler(async (req, res, next) => {
    let { application_id } = req.body
    const tableName = 'application_permissions';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
        { column: 'application_id', operator: '=', value: application_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows[0])
})

exports.UpdateAppPermissions = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'application_permissions', 'permission_id', payload.permission_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

/**
 * app  role_permissions

 */
exports.CreateAppRolePermissions = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'application_role_permissions', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

// exports.FindAppRolePermissions = asynHandler(async (req, res, next) => {
//     let { application_id } = req.body
//     const tableName = 'application_role_permissions';
//     const columnsToSelect = []; // Use string values for column names
//     const conditions = [
//         { column: 'application_id', operator: '=', value: application_id },
//     ];
//     let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
//     if (results.rows.length == 0) {
//         return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
//     }

//     sendResponse(res, 1, 200, "Record Found", results.rows[0])
// })

exports.UpdateAppRolePermissions = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'application_role_permissions', 'role_permission_id', payload.role_permission_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})


