const pool = require("../config/db");
const { prepareColumns } = require("../helper/global");
const { logger } = require("../logs/winston");

let shopdb = {};

shopdb.ShowPlanAccessApplications = (plan_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
    paa.access_id,
    paa.plan_id,
    paa.application_id,
    paa.additional_config_options,
    app.name as application_name,
    app.description as application_description
FROM 
    plan_application_access paa
JOIN 
    applications app ON paa.application_id = app.application_id
WHERE 
    paa.plan_id = $1;

        `, [plan_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

shopdb.ShowTenantSubscription = (tenant_id, status = 'Active') => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
    ts.tenant_subscription_id,
    ts.tenant_id,
    ts.plan_id,
    sp.plan_name,
    ts.start_date,
    ts.end_date,
    ts.status
FROM 
    tenant_subscriptions ts
JOIN 
    subscription_plans sp ON ts.plan_id = sp.plan_id
WHERE 
    ts.tenant_id = $1 -- Replace with the actual tenant ID
    AND ts.status = $2; -- Assuming you want the active subscription


        `, [tenant_id, status], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.ShowTenantSubscriptionPayment = (tenant_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
    ts.tenant_subscription_id,
    ts.tenant_id,
    pm.payment_method_id,
    pm.method_details as payment_method,
    pr.payment_id,
    pr.amount_paid,
    pr.payment_date,
    pr.status as payment_status
FROM 
    tenant_subscriptions ts
LEFT JOIN 
    payment_methods pm ON ts.tenant_id = pm.tenant_id
LEFT JOIN 
    payment_records pr ON ts.tenant_subscription_id = pr.tenant_subscription_id
WHERE 
    ts.tenant_id = $1

        `, [tenant_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

module.exports = shopdb