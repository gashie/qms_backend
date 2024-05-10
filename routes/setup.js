const express = require("express");
const router = express.Router();
// const { userLogin } = require('../middleware/validator')
// const { protect } = require('../middleware/auth')
const { CreateSystemRole, ViewSystemRole, UpdateSystemRole, CreateSystemPermission, ViewSystemPermission, UpdateSystemPermission, CreateRolePermission, ViewRolePermission, CreateSystemRoute } = require("../controllers/system/user_management");
const { VerifyUser, Logout } = require("../controllers/account/auth");
const { protect } = require("../middleware/auth");
const { SetupCompany, UpdateCompany, ViewCompany } = require("../controllers/company/manage");
const { CreateSystemUser } = require("../controllers/account/signup");
const { SetupBranch, ViewBranch, UpdateBranch } = require("../controllers/branch/manage");
const { SetupCounter, ViewCounters, UpdateCounter } = require("../controllers/counter/manage");
const { SetupService, ViewServices, UpdateService, SearchServices } = require("../controllers/services/manage");


//routes

///roles
router.route("/system/create_role").post(CreateSystemRole);
router.route("/system/view_role").post(ViewSystemRole);
router.route("/system/update_role").post(UpdateSystemRole);

//permission
router.route("/system/create_permission").post(CreateSystemPermission);
router.route("/system/view_permission").post(ViewSystemPermission);
router.route("/system/update_permission").post(UpdateSystemPermission);

//role_permission

router.route("/system/create_role_permission").post(CreateRolePermission);
router.route("/system/view_role_permission").post(ViewRolePermission);
router.route("/system/create_routes").post(CreateSystemRoute);

//setup company
router.route("/system/create_company").post(SetupCompany);
router.route("/system/view_company").post(ViewCompany);
router.route("/system/update_company").post(UpdateCompany);


//setup default user
router.route("/system/create_systemuser").post(CreateSystemUser);

// branch management
router.route("/system/create_branch").post(SetupBranch);
router.route("/system/view_branch").post(ViewBranch);
router.route("/system/update_branch").post(UpdateBranch);

// counter management
router.route("/system/create_counter").post(SetupCounter);
router.route("/system/view_counter").post(ViewCounters);
router.route("/system/update_counter").post(UpdateCounter);

// service management
router.route("/system/create_service").post(SetupService);
router.route("/system/view_service").post(ViewServices);
router.route("/system/update_service").post(UpdateService);
router.route("/system/service_search").post(SearchServices);



//user login auth
router.route("/auth").post(protect, VerifyUser);
router.route("/logout").post(protect, Logout);
module.exports = router;
