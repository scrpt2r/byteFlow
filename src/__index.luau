--[[
	******************************************************************************
	* @file		: .../src/utils/constructor.lua
	* @author	: Scrpt2r
	* @date		: April 16 2026
	* @lastEdit	: April 30 2026 21:34
	* @brief	: A highly optimized, buffer-based networking architecture featuring automatic data compression, packet routing, and local signal broadcasting.
    * @version  : 0.3.0
	******************************************************************************
	* @attention
	*
	* Copyright © 2026 Axon Corporation.
	* All rights reserved.
	*
	* This software is licensed under terms that can be found in the LICENSE file
	* in the root directory of this software component.
	* If no LICENSE file comes with this software, it is provided AS-IS.
	*
	******************************************************************************
--]]

--// Lib Decleration
return {
	net = require(script.constructor),
	packet = require(script.libs.utils.packet),
}
