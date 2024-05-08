const pool = require("../config/db");
const { prepareColumns } = require("../helper/global");
const { logger } = require("../logs/winston");

let shopdb = {};



shopdb.ShowLocationPolicies = () => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        l.location_id,
        l.location_name,
        l.location_description,
        l.latitude,
        l.longitude,
        p.policy_id,
        p.polic_name AS policy_name,
        p.policy_description
    FROM 
        public.locations AS l
    LEFT JOIN public.policies AS p
        ON l.policy_id = p.policy_id;
    
        `, [], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

module.exports = shopdb