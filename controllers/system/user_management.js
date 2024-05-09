const asynHandler = require("../../middleware/async");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { ShowRolePermissions } = require("../../model/Account");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.CreateSystemRole = asynHandler(async (req, res, next) => {
    /**
 * Create new role.
 * @param {string} role_name - Name or title of the role - Admin.
 * @param {string} description - Description: Managerial role.
 * @returns {Object} - Object containing role details.
 */
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'roles', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.ViewSystemRole = asynHandler(async (req, res, next) => {
    // let userData = req.user;

    const tableName = 'roles';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        // CatchHistory({ api_response: "No Record Found", function_name: 'ViewSystemRole', date_started: systemDate, sql_action: "SELECT", event: "VIEW SYSTEM ROLE", actor: userData.id }, req)
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }
    // CatchHistory({ api_response: `User with ${userData.id} viewed ${results.rows.length} system role record's`, function_name: 'ViewSystemRole', date_started: systemDate, sql_action: "SELECT", event: "VIEW SYSTEM ROLE", actor: userData.id }, req)

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateSystemRole = asynHandler(async (req, res, next) => {
    let payload = req.body;
    // let userData = req.user;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'roles', 'role_id', payload.role_id)
    if (runupdate.rowCount == 1) {
        // CatchHistory({ payload: JSON.stringify(req.body), api_response: `User with id :${userData.id} updated system roles details`, function_name: 'UpdateSystemRole', date_started: systemDate, sql_action: "UPDATE", event: "UPDATE SYSTEM ROLE", actor: userData.id }, req)
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        // CatchHistory({ payload: JSON.stringify(req.body), api_response: `Update failed, please try later-User with id :${userData.id} updated system roles details`, function_name: 'UpdateSystemRole', date_started: systemDate, sql_action: "UPDATE", event: "UPDATE SYSTEM ROLE", actor: userData.id }, req)
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

/**
 * Permission module.
 * Permission and role permission module.

 */


exports.CreateSystemPermission = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'permissions', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", results.rows)
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})

exports.ViewSystemPermission = asynHandler(async (req, res, next) => {
    const tableName = 'permissions';
    const columnsToSelect = []; // Use string values for column names
    const conditions = [
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})

exports.UpdateSystemPermission = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'permissions', 'permission_id', payload.permission_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})

exports.CreateRolePermission = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'role_permissions', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})
exports.UpdateRolePermission = asynHandler(async (req, res, next) => {
    let payload = req.body;
    payload.updated_at = systemDate

    const runupdate = await GlobalModel.Update(payload, 'role_permissions', 'role_permission_id', payload.role_permission_id)
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record Updated", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})
exports.ViewRolePermission = asynHandler(async (req, res, next) => {
    let { role_id } = req.body

    let results = await ShowRolePermissions(role_id)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, No Record Found", [])
    }

    sendResponse(res, 1, 200, "Record Found", results.rows)
})
exports.ApproveTenantAccount = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let { user_id, tenant_id } = req.body

    const tableName = 'users';
    const columnsToSelect = ['user_id']; // Use string values for column names
    const conditions = [
        { column: 'user_id', operator: '=', value: user_id },
        { column: 'tenant_id', operator: '=', value: tenant_id },
        { column: 'is_approved', operator: '=', value: false },

    ];
    let results = await Finder(tableName, columnsToSelect, conditions)
    let ObjectExist = results.rows[0]

    if (ObjectExist) {
        return sendResponse(res, 0, 200, 'Sorry, please verify if account exist or has been approved already')

    }
    let user_account = {
        approved_at: systemDate,
        is_verified: true,
        is_approved: true
    }
    let tenant_account = {
        approved_at: systemDate,
        is_approved: true
    }

    const runupdate = await GlobalModel.Update(user_account, 'permissions', 'permission_id', payload.permission_id)
    const runupdatetwo = await GlobalModel.Update(tenant_account, 'tenants', 'tenant_id', payload.tenant_id)
    if (runupdate.rowCount == 1 && runupdatetwo.rowCount == 1) {
        return sendResponse(res, 1, 200, "User approved successfully", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})
exports.ApproveUserAccount = asynHandler(async (req, res, next) => {
    let payload = req.body;
    let { user_id,approve } = req.body

    const tableName = 'users';
    const columnsToSelect = ['user_id']; // Use string values for column names
    const conditions = [
        { column: 'user_id', operator: '=', value: user_id },
        { column: 'is_approved', operator: '=', value: true },

    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    let ObjectExist = results.rows[0]

    if (ObjectExist) {
        return sendResponse(res, 0, 200, 'Sorry, please verify if account exist or has been approved already')

    }
    let user_account = {
        approved_at: systemDate,
        is_verified: approve,
        is_approved: approve
    }

    const runupdate = await GlobalModel.Update(user_account, 'users', 'user_id', payload.user_id)
    delete runupdate.rows[0].password
    if (runupdate.rowCount == 1) {
        return sendResponse(res, 1, 200, "User approved successfully", runupdate.rows[0])


    } else {
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }
})


//create route permission
exports.CreateSystemRoute = asynHandler(async (req, res, next) => {

    let payload = req.body;
    let results = await GlobalModel.Create(payload, 'routes', '');
    if (results.rowCount == 1) {
        return sendResponse(res, 1, 200, "Record saved", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])

    }

})