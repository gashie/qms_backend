const asynHandler = require("../../middleware/async");
const bcyrpt = require("bcrypt");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.TenantSignup = asynHandler(async (req, res, next) => {

    let { tenant, account } = req.body

    //create tenant data and return tenant id
    let tenantresult = await GlobalModel.Create(tenant, 'tenants', '');
    let tenantSavedData = tenantresult.rows[0]

    //find is_master role
    const tableName = 'roles';
    const columnsToSelect = ['role_id']; // Use string values for column names
    const conditions = [
        { column: 'is_master_setup', operator: '=', value: true },

    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    let ObjectExist = results.rows[0]

    //generate hashed password
    const salt = await bcyrpt.genSalt(10);
    account.password = await bcyrpt.hash(account.password, salt);
    account.tenant_id = tenantSavedData.tenant_id
    account.is_owner = true

    //save user details to db
    let user_account = await GlobalModel.Create(account, 'users', '');
    let userSavedData = user_account.rows[0]

    let userRolePayload = {
        role_id: ObjectExist.role_id,
        user_id: userSavedData.user_id,
        tenant_id: tenantSavedData.tenant_id
    }
    let create_user_role = await GlobalModel.Create(userRolePayload, 'user_roles', '');

    if (tenantresult.rowCount == 1 && user_account.rowCount == 1 && create_user_role.rowCount == 1) {
        return sendResponse(res, 1, 200, "You have successfully signed up to the platform", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])
    }


})
exports.CreateSystemUser = asynHandler(async (req, res, next) => {

    let { account, role_id } = req.body



    //generate hashed password
    const salt = await bcyrpt.genSalt(10);
    account.password = await bcyrpt.hash(account.password, salt);
    account.is_system_admin = true

    //save user details to db
    let user_account = await GlobalModel.Create(account, 'users', '');
    let userSavedData = user_account.rows[0]

    let userRolePayload = {
        role_id,
        user_id: userSavedData.user_id,
    }
    let create_user_role = await GlobalModel.Create(userRolePayload, 'user_roles', '');

    if (user_account.rowCount == 1 && create_user_role.rowCount == 1) {
        return sendResponse(res, 1, 200, "Account created successfully", [])
    } else {
        return sendResponse(res, 0, 200, "Sorry, error saving record: contact administrator", [])
    }


})
exports.ViewAllUsers = asynHandler(async (req, res, next) => {

    //find is_master role
    const tableName = 'users';
    const columnsToSelect = ['username','email','first_name','last_name','date_of_birth','phone_number','profile_picture_url','created_at','is_system_admin','is_active','is_verified','is_owner','tenant_id']; // Use string values for column names
    const conditions = [];

    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    if (results.rows.length == 0) {
        return sendResponse(res, 0, 200, "Sorry, no record found", [])
    } else {
        return sendResponse(res, 1, 200, "Record Found", results.rows)
    }


})

exports.PasswordReset = asynHandler(async (req, res, next) => {
    let userData = req.user;
    let username = req.body.username
    let {password,old_password,compare_password} = req.body;

    if (password !== compare_password) {
        return sendResponse(res, 0, 200, "Update failed, password doesnt match", [])
    }


    const tableName = 'users';
    const columnsToSelect = ['username','password']; // Use string values for column names
    const conditions = [
        { column: 'username', operator: '=', value: username },

    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, conditions)
    let UserDbInfo = results.rows[0]

    if (!UserDbInfo) {
        CatchHistory({ api_response: "Unauthorized access-username not in database", function_name: 'Auth', date_started: systemDate, sql_action: "SELECT", event: "User Authentication", actor: username }, req)
        return sendResponse(res, 0, 401, 'Unauthorized access')

    }

    //check for password
    const match = await bcyrpt.compare(old_password, UserDbInfo.password)

    if (!match) {
        CatchHistory({ api_response: "Unauthorized access-user exist but password does not match", function_name: 'Auth', date_started: systemDate, sql_action: "SELECT", event: "User Authentication", actor: username }, req)
        return sendResponse(res, 0, 401, 'Unauthorized access')
    }
    

    const salt = await bcyrpt.genSalt(10);
    let payload = {
        password: await bcyrpt.hash(password, salt),
        updated_at: systemDate,
    }


    const runupdate = await GlobalModel.Update(payload, 'account', 'account_id', userData.id)
    if (runupdate.rowCount == 1) {
        CatchHistory({ api_response: `User with id :${userData.id} updated user password`, function_name: 'PasswordReset', date_started: systemDate, sql_action: "UPDATE", event: "Update User password", actor:username}, req)
        return sendResponse(res, 1, 200, "Record Updated",[])


    } else {
        CatchHistory({ api_response: `Update failed, please try later-User with id :${userData.id} updated user password`, function_name: 'PasswordReset', date_started: systemDate, sql_action: "UPDATE", event: "Update user password", actor:username}, req)
        return sendResponse(res, 0, 200, "Update failed, please try later", [])
    }

})