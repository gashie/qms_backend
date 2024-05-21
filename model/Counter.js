const pool = require("../config/db");
const { logger } = require("../logs/winston");

let shopdb = {};




shopdb.showCounterTicket = (counter_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
    t.ticket_id,
    t.token_number,
    t.generated_time,
    t.status,
    t.queue_position,
    t.current_user_id,
    t.last_updated_time,
    t.additional_info,
    s.name AS service_name,
    f.form_name,
    f.form_id,
    b.name AS branch_name,
    c.name AS counter_name,
    ct.assigned_timestamp
FROM 
    public.ticket t
JOIN 
    public.counter_ticket ct ON t.ticket_id = ct.ticket_id
JOIN 
    public.service s ON t.service_id = s.service_id
JOIN 
    public.forms f ON t.form_id = f.form_id
JOIN 
    public.counter c ON ct.counter_id = c.counter_id
JOIN 
    public.branch b ON c.branch_id = b.branch_id
WHERE 
    c.counter_id = $1 AND t.status = $2
ORDER BY 
    ct.assigned_timestamp DESC
LIMIT 1;

    
        `, [counter_id,'Picked'], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

shopdb.listCounterPendintTicket = (counter_id,branch_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
    t.ticket_id,
    t.token_number,
    t.generated_time,
    t.status,
    t.queue_position,
    t.current_user_id,
    t.last_updated_time,
    t.additional_info,
    s.name AS service_name,
    b.name AS branch_name,
    c.name AS counter_name
FROM 
    public.ticket t
JOIN 
    public.queue_item qi ON t.ticket_id = qi.ticket_id
JOIN 
    public.service_counter_assignment sca ON t.service_id = sca.service_id
JOIN 
    public.service s ON t.service_id = s.service_id
JOIN 
    public.counter c ON sca.counter_id = c.counter_id
JOIN 
    public.branch b ON c.branch_id = b.branch_id
WHERE 
sca.counter_id = $1 AND qi.served = $2 AND c.branch_id = $3
ORDER BY 
    t.queue_position
    
        `, [counter_id,false,branch_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.callCounterPendintTicket = (counter_id,branch_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        t.ticket_id,
        t.submission_id,
        t.token_number,
        t.generated_time,
        t.status,
        t.queue_position,
        t.current_user_id,
        t.last_updated_time,
        t.additional_info,
        s.name AS service_name,
        b.name AS branch_name,
        c.name AS counter_name
    FROM 
        public.ticket t
    JOIN 
        public.queue_item qi ON t.ticket_id = qi.ticket_id
    JOIN 
        public.service_counter_assignment sca ON t.service_id = sca.service_id
    JOIN 
        public.service s ON t.service_id = s.service_id
    JOIN 
        public.counter c ON sca.counter_id = c.counter_id
    JOIN 
        public.branch b ON c.branch_id = b.branch_id
    WHERE 
    sca.counter_id = $1 AND qi.served = $2 AND c.branch_id = $3
    ORDER BY 
        t.generated_time
    LIMIT 1;
    
    
        `, [counter_id,false,branch_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.showBranchCounterTicket = (branch_id) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        c.name,
        ct.counter_ticket_id, 
        ct.counter_id, 
        ct.ticket_id, 
        ct.assigned_timestamp, 
        ct.served,
        t.token_number,
        t.branch_id, 
        t.service_id, 
        t.customer_id, 
        t.generated_time, 
        t.status, 
        t.queue_position, 
        t.dispenser_id,
        b.name AS branch_name
    FROM 
        counter_ticket ct
    JOIN 
        ticket t ON ct.ticket_id = t.ticket_id
    JOIN 
        counter c ON ct.counter_id = c.counter_id
    JOIN 
        branch b ON c.branch_id = b.branch_id
    WHERE 
        ct.served = $1 AND c.branch_id = $2;
    
        `, [false, branch_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.counterServices = () => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        sca.service_counter_assignment_id,
        s.service_id,
        s.name AS service_name,
        c.name AS counter_name,
        b.name AS branch_name
    FROM 
        public.service_counter_assignment sca
    JOIN 
        public.service s ON sca.service_id = s.service_id
    JOIN 
        public.counter c ON sca.counter_id = c.counter_id
    JOIN 
        public.branch b ON c.branch_id = b.branch_id;
    
        `, [], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.counterDevices = () => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        d.device_id,
        d.device_name,
        d.device_type,
        d.ip_address,
        b.name AS branch_name,
        c.name AS counter_name
    FROM 
        public.counter_assignments ca
    JOIN 
        public.devices d ON ca.device_id = d.device_id
    JOIN 
        public.branch b ON ca.branch_id = b.branch_id
    JOIN 
        public.counter c ON ca.counter_id = c.counter_id;
    
        `, [], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.findCounterDevices = (ip_address) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        ca.counter_id,
        d.device_id,
        d.branch_id,
        d.device_name,
        d.device_type,
        d.ip_address,
        b.name AS branch_name,
        c.name AS counter_name,
        d.authentication_code,
        d.is_activated

    FROM 
        public.counter_assignments ca
    JOIN 
        public.devices d ON ca.device_id = d.device_id
    JOIN 
        public.branch b ON ca.branch_id = b.branch_id
    JOIN 
        public.counter c ON ca.counter_id = c.counter_id
        WHERE d.ip_address = $1
    
        `, [ip_address], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};

shopdb.findCounterDevicesForActivation = (authentication_code,is_activated,activation_status) => {
    return new Promise((resolve, reject) => {
        pool.query(`
        SELECT 
        ca.counter_id,
        d.device_id,
        d.branch_id,
        d.device_name,
        d.device_type,
        d.ip_address,
        b.name AS branch_name,
        c.name AS counter_name,
        d.authentication_code,
        d.is_activated

    FROM 
        public.counter_assignments ca
    JOIN 
        public.devices d ON ca.device_id = d.device_id
    JOIN 
        public.branch b ON ca.branch_id = b.branch_id
    JOIN 
        public.counter c ON ca.counter_id = c.counter_id
        WHERE d.authentication_code = $1 AND d.is_activated = $2 AND d.activation_status = $3
    
        `, [authentication_code,is_activated,activation_status], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.deleteCounterDevice = (device_id) => {
    return new Promise((resolve, reject) => {
        pool.query("DELETE FROM devices WHERE device_id = $1", [device_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
shopdb.deleteAssignedCounter = (device_id) => {
    return new Promise((resolve, reject) => {
        pool.query("DELETE FROM counter_assignments WHERE device_id = $1", [device_id], (err, results) => {
            if (err) {
                logger.error(err);
                return reject(err);
            }

            return resolve(results);
        });
    });
};
module.exports = shopdb