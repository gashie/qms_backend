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



exports.SearchServices = asynHandler(async (req, res, next) => {
    let { branch_id, service_id } = req.body
    const tableName = 'service';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'parent_service_id', operator: '=', value: service_id },
    ];
    const BranchConditions = [
        { column: 'branch_id', operator: '=', value: branch_id },
        { column: 'parent_service_id', operator: 'IS', value: null },


    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, branch_id ? BranchConditions : ServiceConditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateServiceFields = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'service', 'service_id', payload.service_id)
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


