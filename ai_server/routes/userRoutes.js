const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Placeholder route
router.get('/', userController.getAllUsers);

module.exports = router;