const path = require("path");
const GlobalModel = require("../model/Global");
const { sendResponse } = require("./utilfunc");
module.exports = {

    autoSaveFile: async (file, folder_name,
        folder_location,
        file_name,
        file_type,
        upload_for,
        uploaded_by) => {


        let fileData = {
            folder_name,
            file_name,
            folder_location,
            file_type,
            upload_for,
            uploaded_by
        }
        let results = await GlobalModel.Create(fileData, 'file_uploads', '');
        file.name = `${results.rows[0].upload_id}${path.parse(file.name).ext}`;
        file.mv(`${folder_location}${file.name}`, async (err) => {
            if (err) {
                console.log(err);
                return sendResponse(res, 0, 200, "Problem file upload", [])
            }
        });
        fileData.file_name = file.name
        return fileData;


    },
    validateFormFields: (formFields, submittedData, parameter) => {
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
}