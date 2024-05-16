const pool = require("../config/db");
const { prepareColumns } = require("../helper/global");
const { logger } = require("../logs/winston");

let shopdb = {};



shopdb.ShowDeviceTemplates = () => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT d.device_id, d.device_name,
        d.ip_address, dt.template_id,
        dt.device_template_id, t.template_name,
        t.template_type, t.background_color,
        t.background_video, t.background_image,
        t.assigned_to, t.news_scroll
        FROM public.devices d
        JOIN public.display_device_templates dt ON d.device_id = dt.device_id
        JOIN public.dispenser_templates t ON dt.template_id = t.template_id
    
        `, [], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.ShowMyDeviceTemplates = (ip_address_or_mac) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT d.device_id, d.device_name,
        d.device_type, d.branch_id,
        d.ip_address, dt.template_id,
        dt.device_template_id, t.template_name,
        t.template_type, t.background_color,
        t.background_video, t.background_image,
        t.assigned_to, t.news_scroll
        FROM public.devices d
        JOIN public.display_device_templates dt ON d.device_id = dt.device_id
        JOIN public.dispenser_templates t ON dt.template_id = t.template_id
        WHERE d.ip_address = $1 OR d.device_mac = $1
    
        `, [ip_address_or_mac], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

module.exports = shopdb