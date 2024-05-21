const express = require("express");
const router = express.Router();
// const { userLogin } = require('../middleware/validator')
// const { protect } = require('../middleware/auth')
const { CreateSystemRole, ViewSystemRole, UpdateSystemRole, CreateSystemPermission, ViewSystemPermission, UpdateSystemPermission, CreateRolePermission, ViewRolePermission, CreateSystemRoute } = require("../controllers/system/user_management");
const { VerifyUser, Logout, UserAuth, VerifyCounter } = require("../controllers/account/auth");
const { protect, protectCounter } = require("../middleware/auth");
const { SetupCompany, UpdateCompany, ViewCompany } = require("../controllers/company/manage");
const { CreateSystemUser, CreateTellers } = require("../controllers/account/signup");
const { SetupBranch, ViewBranch, UpdateBranch } = require("../controllers/branch/manage");
const { SetupCounter, ViewCounters, UpdateCounter, AssignServiceToCounter, ViewCounterServices, UpdateCounterServices, RegisterCounterStation, ActivateCounterStation, ViewCounterStationDevices, RevokeCounterStation } = require("../controllers/counter/manage");
const { SetupService, ViewServices, UpdateService, SearchServices } = require("../controllers/services/manage");
const { AssignServiceToForm, SearchServicesFields, UpdateServiceFields, ViewServiceForms } = require("../controllers/services/manage_servicefields");
const { RegisterDevice, ActivateDevice } = require("../controllers/devices/manage");
const { CreateDispenserTemplate, AssignTemplateToDispenser, UpdateDispenserTemplate, UpdateAssignedTemplate, ViewAssignedTemplate, ViewDispenserTemplate, SetupTemplateExchangeRate, ViewTemplateExchangeRate, UpdateTemplateExchangeRate, UpdateDispenserCarouselTemplate } = require("../controllers/devices/dispenser");
const { OpenDisplayView } = require("../controllers/devices/view");
const { SetupForm, ViewForms, UpdateForm, SetupFormFields, SearchFormFields, UpdateFormFields } = require("../controllers/form/manage");
const { GenerateNewTicket } = require("../controllers/ticket/manage");
const { protectUser } = require("../middleware/userauth");
const { ListPendingTicket, ProcessTicket, ShowCounterServing, CallPendingTicket } = require("../controllers/ticket/process");


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
router.route("/system/add_teller").post(CreateTellers);

// branch management
router.route("/system/create_branch").post(SetupBranch);
router.route("/system/view_branch").post(ViewBranch);
router.route("/system/update_branch").post(UpdateBranch);

// counter management
router.route("/system/create_counter").post(SetupCounter);

router.route("/system/view_counter").post(ViewCounters);
router.route("/system/update_counter").post(UpdateCounter);

router.route("/system/assign_service_to_counter").post(AssignServiceToCounter);
router.route("/system/view_counter_services").post(ViewCounterServices);
router.route("/system/update_counter_services").post(UpdateCounterServices);

router.route("/system/setup_counter_station").post(RegisterCounterStation);
router.route("/system/activate_counter_station").post(ActivateCounterStation);
router.route("/system/view_counter_devices").post(ViewCounterStationDevices);
router.route("/system/revoke_counter_devices").post(RevokeCounterStation);


// service management
router.route("/system/create_service").post(SetupService);
router.route("/system/view_service").post(ViewServices);
router.route("/system/update_service").post(UpdateService);
router.route("/system/service_search").post(SearchServices);


// form management
router.route("/system/create_form").post(SetupForm);
router.route("/system/view_forms").post(ViewForms);
router.route("/system/update_form").post(UpdateForm);
router.route("/system/add_form_fields").post(SetupFormFields);
router.route("/system/search_formfields").post(SearchFormFields);
router.route("/system/update_form_fields").post(UpdateFormFields);


// service fields
router.route("/system/assign_service_to_form").post(AssignServiceToForm);
router.route("/system/view_service_form").post(ViewServiceForms);
router.route("/system/search_service_form").post(SearchServicesFields);
router.route("/system/update_service_form").post(UpdateServiceFields);


// manage devices
router.route("/system/register_device").post(RegisterDevice);
router.route("/system/activate_device").post(ActivateDevice);

//device template
//--->dispenser
router.route("/system/create_dispenser_template").post(CreateDispenserTemplate);
router.route("/system/view_dispenser_template").post(ViewDispenserTemplate);
router.route("/system/update_dispenser_template").post(UpdateDispenserTemplate);
router.route("/system/update_dispenser_carousel_template").post(UpdateDispenserCarouselTemplate);
router.route("/system/assign_to_template").post(AssignTemplateToDispenser);
router.route("/system/view_assigned_template").post(ViewAssignedTemplate);
router.route("/system/update_assigned_template").post(UpdateAssignedTemplate);
router.route("/system/create_templaterate").post(SetupTemplateExchangeRate);
router.route("/system/view__templaterate").post(ViewTemplateExchangeRate);
router.route("/system/update__templaterate").post(UpdateTemplateExchangeRate);

//open display view
router.route("/system/open_displayview").post(protect,OpenDisplayView);

//tickets
router.route("/system/generate_ticket").post(protect,GenerateNewTicket);
router.route("/system/pending_ticket").post(protectUser,protectCounter,ListPendingTicket);
router.route("/system/call_pending_ticket").post(protectUser,protectCounter,CallPendingTicket);
router.route("/system/process_ticket").post(protectUser,protectCounter,ProcessTicket);
router.route("/system/show_currently_serving").post(protectUser,protectCounter,ShowCounterServing);

//user login auth
router.route("/auth").post(protectUser, VerifyUser);
router.route("/counter_auth").post(protectCounter, VerifyCounter);
router.route("/user_login").post(UserAuth);
router.route("/logout").post(protect, Logout);
module.exports = router;
