
// // Assuming you have a function to query your database
// async function queryServices() {
//     // Query your database to get the services
//     // This function should return an array of service objects
//     // Each service object should have at least the fields mentioned in your data
//     // Replace this with your actual database query logic
//     return [
//         {
//             "service_id": "b8b8590e-d361-4fb7-b9e0-9adf092e161f",
//             "branch_id": "2c8d24d6-fd4d-4df6-b120-57d727a9bf26",
//             "parent_service_id": null,
//             "name": "Transfer",
//             "label": "Funds Transfer",
//             "image_url": "",
//             "color": "yellow",
//             "text_below": "FT Cash",
//             "description": "transfer to account",
//             "created_at": "2024-05-09T16:09:10.131Z",
//             "updated_at": "2024-05-09T16:08:48.000Z",
//             "created_by": null,
//             "icon": "fa-fatimes"
//         },
//         {
//             "service_id": "9ba86dba-aa93-4d5d-b427-5ba02f324e05",
//             "branch_id": "2c8d24d6-fd4d-4df6-b120-57d727a9bf26",
//             "parent_service_id": "b8b8590e-d361-4fb7-b9e0-9adf092e161f",
//             "name": "Momo Transfer",
//             "label": "Funds Transfer Momo",
//             "image_url": "",
//             "color": "green",
//             "text_below": "FT Cash",
//             "description": "transfer to account",
//             "created_at": "2024-05-09T16:09:10.131Z",
//             "updated_at": "2024-05-09T16:08:48.000Z",
//             "created_by": null,
//             "icon": "fa-fatimes"
//         }
//     ];
// }

// // Recursive function to build the tree structure
// async function buildServiceTree(parentId = null) {
//     const services = await queryServices();
//     const children = services.filter(service => service.parent_service_id === parentId);
    
//     // For each child, recursively build its subtree
//     for (const child of children) {
//         const childId = child.service_id;
//         const grandchildren = await buildServiceTree(childId);
//         child.children = grandchildren;
//     }
    
//     return children;
// }

// // Example usage:
// buildServiceTree().then(tree => {
//     console.log(tree);
// }).catch(error => {
//     console.error(error);
// });

// var voucher_codes = require('voucher-code-generator');

// let code = voucher_codes.generate({
//     prefix: "HQ-",
//     postfix: "-COUNTER2",
//     length: 8,
//     count: 1,
//     charset:'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
// });

// console.log('====================================');
// console.log(code[0]);
// console.log('====================================');


function validateFormFields(formFields, submittedData, parameter) {
    const errors = [];
    const validatedFields = [];
  
    // Extract submission content
    const submittedFields = submittedData.content.submission_content;
  
    // Loop through form fields to find those that match the parameter
    formFields.forEach(field => {
      if (field[parameter]) {
        // Find the corresponding submitted field by field_id
        const submittedField = submittedFields.find(sub => sub.field_id === field.field_id);
  
        if (!submittedField) {
          errors.push(`Field ${field.label} is missing in the submission`);
        } else {
          // Add custom validation logic here if needed
          validatedFields.push({
            field_id: field.field_id,
            label: field.label,
            response: submittedField.response
          });
        }
      }
    });
  
    return {
      validatedFields,
      errors
    };
  }
  
  // Example usage
  const formFields = [
    {
      "field_id": "1e6a1294-ec6a-4383-a9b7-9c0f5ec07ad5",
      "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
      "label": "Amount",
      "field_type": "number",
      "is_required": true,
      "options_endpoint": null,
      "is_verified": false,
      "verification_endpoint": null,
      "order_index": 1,
      "created_by": null,
      "created_at": "2024-05-19T12:44:01.594Z",
      "updated_at": null,
      "options": null,
      "show_on_receipt": true,
      "is_amount": false,
      "default_value": null,
      "tooltip": null,
      "show_in_remarks": true,
      "is_contact": false,
      "is_email": false,
      "is_unique": false,
      "is_account_number": false,
      "is_account_name": false
    },
    {
      "field_id": "ae1f4a37-ac14-4d52-bb9a-44102d096ff0",
      "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
      "label": "Fullname",
      "field_type": "text",
      "is_required": false,
      "options_endpoint": null,
      "is_verified": false,
      "verification_endpoint": null,
      "order_index": 3,
      "created_by": null,
      "created_at": "2024-05-19T12:44:01.607Z",
      "updated_at": null,
      "options": null,
      "show_on_receipt": true,
      "is_amount": false,
      "default_value": null,
      "tooltip": null,
      "show_in_remarks": true,
      "is_contact": false,
      "is_email": false,
      "is_unique": false,
      "is_account_number": false,
      "is_account_name": false
    },
    {
      "field_id": "a4db0619-814b-4d2e-9de6-a97e57cb641d",
      "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
      "label": "Email",
      "field_type": "text",
      "is_required": true,
      "options_endpoint": null,
      "is_verified": false,
      "verification_endpoint": null,
      "order_index": 4,
      "created_by": null,
      "created_at": "2024-05-19T12:44:01.611Z",
      "updated_at": null,
      "options": null,
      "show_on_receipt": true,
      "is_amount": false,
      "default_value": null,
      "tooltip": null,
      "show_in_remarks": true,
      "is_contact": false,
      "is_email": false,
      "is_unique": false,
      "is_account_number": false,
      "is_account_name": false
    },
    {
      "field_id": "d89d3f33-9b0a-4f83-a341-c0a1a1ee9078",
      "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
      "label": "Phone",
      "field_type": "number",
      "is_required": true,
      "options_endpoint": null,
      "is_verified": false,
      "verification_endpoint": null,
      "order_index": 5,
      "created_by": null,
      "created_at": "2024-05-19T12:44:01.614Z",
      "updated_at": null,
      "options": null,
      "show_on_receipt": false,
      "is_amount": false,
      "default_value": null,
      "tooltip": null,
      "show_in_remarks": true,
      "is_contact": true,
      "is_email": false,
      "is_unique": false,
      "is_account_number": false,
      "is_account_name": false
    }
  ];
  
  const submittedData = {
    "content": {
      "submission_content": [
        {
          "field_id": "1e6a1294-ec6a-4383-a9b7-9c0f5ec07ad5",
          "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
          "label": "Amount",
          "field_type": "number",
          "order_index": 1,
          "response": 200
        },
        {
          "field_id": "ae1f4a37-ac14-4d52-bb9a-44102d096ff0",
          "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
          "label": "Fullname",
          "field_type": "text",
          "response": "Richard Baffoe"
        },
        {
          "field_id": "a4db0619-814b-4d2e-9de6-a97e57cb641d",
          "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
          "label": "Email",
          "field_type": "text",
          "response": "richardwilliam60@gmail.com"
        },
        {
          "field_id": "d89d3f33-9b0a-4f83-a341-c0a1a1ee9078",
          "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
          "label": "Phone",
          "field_type": "number",
          "order_index": 1,
          "response": "0269313257"
        }
      ]
    }
  };
  
  const parameter = 'show_on_receipt';
  
  const result = validateFormFields(formFields, submittedData, parameter);
  console.log('Validated Fields:', result.validatedFields);
  console.log('Errors:', result.errors);
  

// function autoValidateFormFields(formFields, submittedData) {
//     const errors = [];
//     const validatedFields = [];
  
//     // Extract submission content
//     const submittedFields = submittedData.content.submission_content;
  
//     formFields.forEach(field => {
//       const submittedField = submittedFields.find(sub => sub.field_id === field.field_id);
  
//       // Validate if field is required
//       if (field.is_required && (!submittedField || !submittedField.response)) {
//         errors.push(`Field ${field.label} is required but not provided.`);
//         return;
//       }
  
//       // Validate if field is contact
//       if (field.is_contact && submittedField && !isValidPhoneNumber(submittedField.response)) {
//         errors.push(`Field ${field.label} should be a valid phone number.`);
//         return;
//       }
  
//       // Validate if field is email
//       if (field.is_email && submittedField && !isValidEmail(submittedField.response)) {
//         errors.push(`Field ${field.label} should be a valid email address.`);
//         return;
//       }
  
//       // Validate if field is amount
//       if (field.is_amount && submittedField && !isValidAmount(submittedField.response)) {
//         errors.push(`Field ${field.label} should be a valid amount.`);
//         return;
//       }
  
//       // Validate if field is verified
//       if (field.is_verified && submittedField && !submittedField.is_verified) {
//         errors.push(`Field ${field.label} should be verified.`);
//         return;
//       }
  
//       // If no errors, add to validated fields
//       if (submittedField) {
//         validatedFields.push({
//           field_id: field.field_id,
//           label: field.label,
//           response: submittedField.response
//         });
//       }
//     });
  
//     return {
//       validatedFields,
//       errors
//     };
//   }
  
//   // Helper functions for validation
//   function isValidPhoneNumber(phone) {
//     const phoneRegex = /^[0-9]{10,15}$/; // Adjust regex as needed
//     return phoneRegex.test(phone);
//   }
  
//   function isValidEmail(email) {
//     const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
//     return emailRegex.test(email);
//   }
  
//   function isValidAmount(amount) {
//     return !isNaN(amount) && parseFloat(amount) > 0;
//   }
  
//   // Example usage
//   const formFields = [
//     {
//       "field_id": "1e6a1294-ec6a-4383-a9b7-9c0f5ec07ad5",
//       "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
//       "label": "Amount",
//       "field_type": "number",
//       "is_required": true,
//       "options_endpoint": null,
//       "is_verified": false,
//       "verification_endpoint": null,
//       "order_index": 1,
//       "created_by": null,
//       "created_at": "2024-05-19T12:44:01.594Z",
//       "updated_at": null,
//       "options": null,
//       "show_on_receipt": true,
//       "is_amount": true,
//       "default_value": null,
//       "tooltip": null,
//       "show_in_remarks": true,
//       "is_contact": false,
//       "is_email": false,
//       "is_unique": false,
//       "is_account_number": false,
//       "is_account_name": false
//     },
//     {
//       "field_id": "a4db0619-814b-4d2e-9de6-a97e57cb641d",
//       "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
//       "label": "Email",
//       "field_type": "text",
//       "is_required": true,
//       "options_endpoint": null,
//       "is_verified": false,
//       "verification_endpoint": null,
//       "order_index": 4,
//       "created_by": null,
//       "created_at": "2024-05-19T12:44:01.611Z",
//       "updated_at": null,
//       "options": null,
//       "show_on_receipt": true,
//       "is_amount": false,
//       "default_value": null,
//       "tooltip": null,
//       "show_in_remarks": true,
//       "is_contact": false,
//       "is_email": true,
//       "is_unique": false,
//       "is_account_number": false,
//       "is_account_name": false
//     },
//     {
//       "field_id": "d89d3f33-9b0a-4f83-a341-c0a1a1ee9078",
//       "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
//       "label": "Phone",
//       "field_type": "number",
//       "is_required": true,
//       "options_endpoint": null,
//       "is_verified": false,
//       "verification_endpoint": null,
//       "order_index": 5,
//       "created_by": null,
//       "created_at": "2024-05-19T12:44:01.614Z",
//       "updated_at": null,
//       "options": null,
//       "show_on_receipt": false,
//       "is_amount": false,
//       "default_value": null,
//       "tooltip": null,
//       "show_in_remarks": true,
//       "is_contact": true,
//       "is_email": false,
//       "is_unique": false,
//       "is_account_number": false,
//       "is_account_name": false
//     }
//   ];
  
//   const submittedData = {
//     "content": {
//       "submission_content": [
//         {
//           "field_id": "1e6a1294-ec6a-4383-a9b7-9c0f5ec07ad5",
//           "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
//           "label": "Amount",
//           "field_type": "number",
//           "order_index": 1,
//           "response": "ds"
//         },
//         {
//           "field_id": "a4db0619-814b-4d2e-9de6-a97e57cb641d",
//           "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
//           "label": "Email",
//           "field_type": "text",
//           "response": "richardwilliam60@gmail.com"
//         },
//         {
//           "field_id": "d89d3f33-9b0a-4f83-a341-c0a1a1ee9078",
//           "form_id": "35aa8f89-574a-44f6-ab3c-13786a7887eb",
//           "label": "Phone",
//           "field_type": "number",
//           "order_index": 1,
//           "response": "026931325sd"
//         }
//       ]
//     }
//   };
  
//   const result = autoValidateFormFields(formFields, submittedData);
//   console.log('Validated Fields:', result);
//   console.log('Errors:', result.errors);
  