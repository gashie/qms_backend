const asynHandler = require("../../middleware/async");
const licenseKey = require('license-key-gen');
const customId = require("custom-id");
const path = require("path");
const { sendResponse, CatchHistory } = require("../../helper/utilfunc");
const GlobalModel = require("../../model/Global");
const { GenerateTicket } = require("../../model/Ticket");
const { validateFormFields } = require("../../helper/func");
const { findUniqueCustomer } = require("../../model/Customer");
const systemDate = new Date().toISOString().slice(0, 19).replace("T", " ");

exports.GenerateNewTicket = asynHandler(async (req, res, next) => {
    let device = req.device_template

    let { service_id, form_id, content } = req.body
    /**
 * Create new company.
 * @param {string} name - Name or title of the branch.
 * @param {string} description - Description: .
 * @returns {Object} - Object containing branch details.
 */
    //find form
    const tableName = 'form_fields';
    const status = 'Pending';
    const columnsToSelect = []; // Use string values for column names
    const ServiceConditions = [
        { column: 'form_id', operator: '=', value: form_id },
    ];
    let results = await GlobalModel.Finder(tableName, columnsToSelect, ServiceConditions)

    const tableNameTwo = 'branch';
    const columnsToSelectTwo = []; // Use string values for column names
    const ServiceConditionsTwo = [
        { column: 'branch_id', operator: '=', value: device.branch_id },
    ];
    let branch_result = await GlobalModel.Finder(tableNameTwo, columnsToSelectTwo, ServiceConditionsTwo)


    const parameter_unique = 'is_unique';
    const parameter_email = 'is_email';
    const parameter_account_name = 'is_account_name'
    const parameter_account_number = 'is_account_number'
    const parameter_is_contact = 'is_contact'
    const parameter_is_amount = 'is_amount'
    const parameter_show_on_receipt = 'show_on_receipt';
    const parameter_show_in_remarks = 'show_in_remarks';
    let branch = branch_result.rows[0]
    const unique_field = validateFormFields(results.rows, req.body, parameter_unique);
    let unique = unique_field.validatedFields[0]?.response

    const email_field = validateFormFields(results.rows, req.body, parameter_email);
    let email = email_field.validatedFields[0]?.response


    const account_name_field = validateFormFields(results.rows, req.body, parameter_account_name);
    let account_name = account_name_field.validatedFields[0]?.response

    const account_number_field = validateFormFields(results.rows, req.body, parameter_account_number);
    let account_number = account_number_field.validatedFields[0]?.response

    const amount_field = validateFormFields(results.rows, req.body, parameter_is_amount);
    let amount = amount_field.validatedFields[0]?.response


    const receipt_field = validateFormFields(results.rows, req.body, parameter_show_on_receipt);
    let receipt = receipt_field.validatedFields[0]

    const remarks_field = validateFormFields(results.rows, req.body, parameter_show_in_remarks);
    let remarks = remarks_field.validatedFields[0]

    const contact_field = validateFormFields(results.rows, req.body, parameter_is_contact);
    let phone_number = contact_field.validatedFields[0]?.response

    //Pick out unique field to search for customer
    let customerPayload = {
        full_name: account_name,
        email,
        phone_number
    }
    let check_customer = await findUniqueCustomer(unique);
    //--CHECK IF CUSTOMER EXIST
    var customer_id = null;
    if (check_customer.rows.length == 0) {
        //-> IF NOT SAVE CUSTOMER AND RETURN CUSTOMER ID
        saved_customer = await GlobalModel.Create(customerPayload, 'customers', '');

        // Check if the query returned the expected data
        if (saved_customer.rowCount === 1) {
            customer_id = saved_customer.rows[0].customer_id;
            console.log('Customer ID:', customer_id);
        }
    }
    customer_id = customer_id || check_customer.rows[0]?.customer_id
    //create submission payload



    customerPayload.customer_id = customer_id

    let submission = {
        form_id,
        service_id,
        branch_id:device.branch_id,
        dispenser_id:device.device_id,
        unique_field: unique,
        remarks,
        receipt,
        amount,
        account_number,
        account_name,
        customer_id,
        email,
        phone_number,
        submitted_data: content,
        status
    }
    saved_submission = await GlobalModel.Create(submission, 'submitted_forms', '');
    let acronym = branch?.name.toUpperCase().substring(0,2)  ?? branch?.name.toUpperCase().substring(0,2) 

    // Check if the query returned the expected data
    if (saved_submission.rowCount === 1) {
        let submission_id = saved_submission.rows[0].submission_id;
        let refresult = await GenerateTicket(acronym,device.branch_id,service_id,customer_id,status,dispenser_id,form_id,submission_id);
        if (refresult.rowCount == 1) {
            return sendResponse(res, 1, 200, "Ticket generated", refresult.rows)
        } else {
            return sendResponse(res, 0, 200, "Sorry, error generating ticket", [])
    
        }

    }else {
        return sendResponse(res, 0, 200, "Sorry, error saving form", [])

    }



})

