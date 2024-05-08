const bcyrpt = require("bcrypt");
const GlobalModel = require("../model/Global");
const { generateApiKey } = require('generate-api-key');
module.exports = {
    autoProcessPolicyEnrollment: async (req, policy) => {


        let { polic_name } = req.body
        let generatekey = generateApiKey({
            method: 'uuidv4',
            name: polic_name.replace(/ /g, "_"),
            namespace: policy[0]?.policy_id,
            prefix: `ent_${polic_name.replace(/ /g, "_")}`
        });

        // const salt = await bcyrpt.genSalt(10);
        // let token = await bcyrpt.hash(generatekey, salt);

        let enrollPayload = {
            token:generatekey,
            token_description: `enrollment token for ${polic_name}`,
            policy_id: policy[0]?.policy_id,
        }

        GlobalModel.Create(enrollPayload, 'enrollment_tokens', '');
        return { enrollment_token: generatekey, policy_id: policy[0]?.policy_id, }

    },
    autoProcessServiceToken: async (req, fleet) => {


        let { fleet_name } = req.body
        let generatekey = generateApiKey({
            method: 'uuidv4',
            name: fleet_name.replace(/ /g, "_"),
            namespace: fleet[0]?.fleet_id,
            prefix: `st_${fleet_name.replace(/ /g, "_")}`
        });

        const salt = await bcyrpt.genSalt(10);
        let token = await bcyrpt.hash(generatekey, salt);

        let enrollPayload = {
            service_token:token,
            token_name: `fleet_token_${fleet_name}`,
            fleet_id: fleet[0]?.fleet_id,
        }

        GlobalModel.Create(enrollPayload, 'service_token', '');
        return { service_token: generatekey, fleet_id: fleet[0]?.fleet_id, }

    },


}