const express = require('express');
const router = express.Router();
const db = require('../config/db'); // Adjust the path to your database module
const path = require('path');
const fs = require('fs');
const { sendResponse } = require('../helper/utilfunc');
const asyncHandler = require('../middleware/async');

// Load Controllers and Middleware
const loadControllers = (dirPath) => {
    let controllers = {};
    const items = fs.readdirSync(dirPath);

    items.forEach(item => {
        const itemPath = path.join(dirPath, item);
        const stats = fs.statSync(itemPath);

        if (stats.isDirectory()) {
            controllers = { ...controllers, ...loadControllers(itemPath) };
        } else if (item.endsWith('.js')) {
            const controller = require(itemPath);
            controllers = { ...controllers, ...controller };
        }
    });

    return controllers;
};

const loadMiddleware = () => {
    const middlewares = {};
    const middlewarePath = path.join(__dirname, '../middleware');
    const middlewareFiles = fs.readdirSync(middlewarePath);

    middlewareFiles.forEach(file => {
        if (file.endsWith('.js')) {
            const middlewareModule = require(path.join(middlewarePath, file));
            Object.assign(middlewares, middlewareModule);
        }
    });

    return middlewares;
};

const middlewares = loadMiddleware();
const controllers = loadControllers(path.join(__dirname, '../controllers'));
router.all('*', async (req, res,next) => {
    try {
        const path = req.path;
        const method = req.method.toUpperCase();

        // Fetch route configuration from the database
        const routeConfig = await db.query('SELECT * FROM routes WHERE routes_path = $1 AND routes_method = $2', [path, method]);
         
        if (routeConfig.rowCount === 0) {
            return sendResponse(res, 0, 200, "Sorry, route or method failed", []);
        }

        const route = routeConfig.rows[0];
        const routeMiddlewareNames = (route.middleware || '').split(',').map(mw => mw.trim());
        const routeMiddlewares = routeMiddlewareNames.map(name => middlewares[name]).filter(mw => mw);

        const controllerFunction = controllers[route.controller_function];
        if (!controllerFunction) {
            console.error(`Controller function '${route.controller_function}' not found.`);
            return sendResponse(res, 0, 200, "Sorry, this route does not exist", []);
        }

        // Wrap the controller function with asynHandler
        const wrappedController = asyncHandler(controllerFunction);

        // Execute middleware(s) and then the wrapped controller
        const executeMiddlewares = (index) => {
            if (index < routeMiddlewares.length) {
                routeMiddlewares[index](req, res, () => executeMiddlewares(index + 1));
            } else {
                // Call the wrapped controller here
                wrappedController(req, res, next);
            }
        };

        executeMiddlewares(0);

    } catch (error) {
        console.error('Error processing dynamic route:', error);
        return sendResponse(res, 0, 200, "System failed to process your request, contact administrator", []);
    }
});

module.exports = router;