cwr3_all_units = [];

cwr3_salute_distance = 2;
cwr3_salute_duration = 2;

// action conditions
//cwr3_notInVehicleCond = "_originalTarget == _target";
cwr3_notInVehicleCond = "vehicle _target == _target";
// cwr3_selfCond = "_originalTarget == _this"; //  && _this == player
cwr3_selfCond = "_target == player"; //  && _this == player

cwr3_dragCond = "isNull attachedTo _target && count attachedObjects _this == 0 && _target distance _this < 3";
cwr3_weaponToBackCond = format ["%1 && %2 && %3", cwr3_notInVehicleCond, cwr3_selfCond, "player getVariable 'cwr3_weapon_on_back' == 0"];
cwr3_weaponToHandCond = format ["%1 && %2 && %3", cwr3_notInVehicleCond, cwr3_selfCond, "player getVariable 'cwr3_weapon_on_back' == 1"];
cwr3_notInVehicleCondAndSelf = format ["%1 && %2", cwr3_notInVehicleCond, cwr3_selfCond];
cwr3_notInVehicleAndNearCond = format ["%1 && %2", cwr3_notInVehicleCond, "_target distance _this < 3"];
cwr3_notInVehicleCondAndSelfAndSoldiersNearby = format ["%1 && %2", cwr3_notInVehicleCondAndSelf, format ["(count (_target nearEntities [""Man"", %1])) > 1", cwr3_salute_distance]];

// events
cwr3_fn_onUnitKilled = {
    _unit = param [0];

//    diag_log format ["CWR3: unit killed %1", _unit];
    if (!(unit isKindOf "man")) exitWith { false; };

    _unit addAction [localize "STR_cwr3_action_drag_body", cwr3_action_dragBody, nil, 6, false, false, "", cwr3_dragCond];

    _actionId = _unit getVariable ["cwr3_getOver_action_id", -1];
    if (_actionId > -1) then {
        _unit removeAction _actionId;
    };
};

// drag and drop body functions
cwr3_fn_moveBody = {
    _unit = _thisArgs # 0;
    _player = _thisArgs # 1;

    // CREDIT TO Das Attorney FOR CODE
    _pos  = _player modelToWorld [0, 1, 0];
    _unit setPos _pos;
    _unit setDir 180;
    _unit switchMove "AinjPpneMrunSnonWnonDb";

//    diag_log format ["CWR3: move body %1 by %2", _unit, _player];
};

cwr3_fn_attachBody = {
    _unit = param [0];
    _player = param [1];

    _unit attachTo [_player, [0, 1, 0]];

    _id = addMissionEventHandler ["EachFrame", cwr3_fn_moveBody, [_unit, _player]];

    _player setVariable ["moveBodyId", _id];
};

cwr3_fn_detachBody = {
    _unit = param [0];
    _player = param [1];

    _id = _player getVariable "moveBodyId";

    removeMissionEventHandler ["EachFrame", _id];

    sleep 0.05;

    _relD = [_unit, _player] call BIS_fnc_dirTo;
    _pos  = _player modelToWorld [0, 1, 0];
    _unit switchMove "AinjPpneMstpSnonWrflDb_release";
    _unit setDir _relD;
    _unit setPos _pos;

    detach _unit;
};

// weapon on back to hand helpers
cwr3_fn_getCurrentWeaponIndex = {
  _unit = param [0, player];
  _weps = weapons _unit;
  _wep = currentWeapon _unit;

  _index = -1;
  {
    if (_x == _wep) exitWith {
      _index = _forEachIndex;
    };
  } forEach _weps;

//  diag_log format ["CWR3: getCurrentWeaponIndex %1", _index];
  _index;
};

cwr3_fn_getPrevWeaponIndex = {
  _unit = param [0, player];
  _unit getVariable ["cwr3_prev_weapon", -1];
};

// actions
cwr3_action_weaponToBack = {
    params ["_target", "_caller", "_actionId", "_arguments"];
    _index = [_target] call cwr3_fn_getCurrentWeaponIndex;
    _target setVariable ["cwr3_prev_weapon", _index];
    _target action ["SWITCHWEAPON", _target, _target, -1];
    _target setVariable ["cwr3_weapon_on_back", 1];
    disableUserInput true;
    sleep 2.4;
    disableUserInput false;
};

// does not work on units ?
cwr3_action_weaponToHand = {
    params ["_target", "_caller", "_actionId", "_arguments"];
    _wIndex = [_target] call cwr3_fn_getPrevWeaponIndex;
    _target action ["SWITCHWEAPON", _target, _target, _wIndex];
    _target setVariable ["cwr3_weapon_on_back", 0];
    _actionId = player getVariable "cwr3_to_back_action_id";
    _str = localize "STR_cwr3_action_on_back";
    if (_wIndex == 1) then {
      _str = localize "STR_cwr3_action_holster";
    };
    player setUserActionText [_actionId, _str];

//    disableUserInput true;
//    sleep 2;
//    disableUserInput false;
};

cwr3_action_dropBody = {
    _unit = param [3];

    // GLOBAL CODE
    [_unit, player] call cwr3_fn_detachBody;

    _dropId = player getVariable "dropActionId";

    // CLIENT SIDE
    player removeAction _dropID;
    player playMove "amovpknlmstpsraswrfldnon";
    player forceWalk false;
};

cwr3_action_dragBody = {
    _unit = param [0];

    // GLOBAL CODE
    [_unit, player] call cwr3_fn_attachBody;

    // CLIENT SIDE
    player playAction "grabDrag";
    player forceWalk true;

    _dropID = player addAction [localize "STR_cwr3_action_release_body", cwr3_action_dropBody, _unit, 6];

    player setVariable ["dropActionId", _dropID];
};

cwr3_make_salute = {
  _target = param [0];
  _to = param [1];
  _duration = param [2, cwr3_salute_duration];
  if (! isNil "_to") then {
//    _relDir = getDir _target - getDir _to;
//    _target setDir _relDir;

    _target doWatch _to;
    sleep 1;
    _duration = _duration + 1;
  };
  _target action ["SALUTE", _target];
  sleep _duration;
  _target action ["SALUTE", _target];
};

cwr3_action_getOver = {
    params ["_target", "_caller", "_actionId", "_arguments"];
    diag_log format ["CWR3: playing action GetOver on %1", _target];
    _target action ["GetOver", _target];
};

// action dispatchers
cwr3_fn_addToBackAction = {
    _unit = param [0, player];
    _actionId = _unit addAction [localize "STR_cwr3_action_on_back", cwr3_action_weaponToBack, nil, 6, false, false, "", cwr3_weaponToBackCond, 1];
    _unit setVariable ["cwr3_to_back_action_id", _actionId];
};
cwr3_fn_addToHandAction = {
    _unit = param [0, player];
    _actionId = _unit addAction [localize "STR_cwr3_action_in_hand", cwr3_action_weaponToHand, nil, 6, false, false, "", cwr3_weaponToHandCond, 1];
    _unit setVariable ["cwr3_in_hand_action_id", _actionId];
};

cwr3_fn_addGetOverAction = {
    _unit = param [0, player];
    _actionId = _unit addAction [actionName "GetOver", cwr3_action_getOver, nil, 6, false, false, "", cwr3_notInVehicleCond];
    _unit setVariable ["cwr3_getOver_action_id", _actionId, true];
};

// for player
[] spawn {
  waitUntil { alive player; };

  // regroup
  if (isNil "cwr3_disableRegroup") then {
    cwr3_areaClear = true;
    [] spawn {
      cwr3_areaClear = false;
      while {true} do {
        _myNearestEnemy = player findNearestEnemy player;
        cwr3_areaClear = _myNearestEnemy isEqualTo objNull;
        sleep 5;
      };
    };
    player addAction [
      localize "STR_cwr3_action_regroup",
      cwr3_fnc_regroup,
      nil,
      5,
      false,
      false,
       "",
       format ["%1 && %2", cwr3_notInVehicleCondAndSelf, "cwr3_areaClear"],
       1
     ];
  };

  if (isNil "cwr3_disableSalute") then {
    cwr3_salute_handler_id = addUserActionEventHandler ["Salute", "Activate", {
      _spot =  player getRelPos [cwr3_salute_distance, 0];
      _list = _spot nearEntities ["Man", cwr3_salute_distance] - [player];
      diag_log format [' .. %1', _list];
      if (count _list > 0) then {
        _first = _list # 0;
        [_first, player, cwr3_salute_duration] spawn cwr3_make_salute;
      };
      [cwr3_salute_duration + 1] spawn {
        sleep param [0];
        player action ["SALUTE", player];
      };
    }];
  };
  if (isNil "cwr3_disableWeaponOnBack") then {
    player setVariable ["cwr3_prev_weapon", -1];
    player setVariable ["cwr3_weapon_on_back", 0];
    [player] call cwr3_fn_addToBackAction;
    [player] call cwr3_fn_addToHandAction;
    addUserActionEventHandler ["SwitchPrimary", "Activate", {
      _index = [player] call cwr3_fn_getCurrentWeaponIndex;
      player setVariable ["cwr3_prev_weapon", _index];
      player setVariable ["cwr3_weapon_on_back", 0];
      _actionId = player getVariable "cwr3_to_back_action_id";
      player setUserActionText [_actionId, localize "STR_cwr3_action_on_back"];
    }];
    addUserActionEventHandler ["SwitchHandgun", "Activate", {
      _index = [player] call cwr3_fn_getCurrentWeaponIndex;
      player setVariable ["cwr3_prev_weapon", _index];
      player setVariable ["cwr3_weapon_on_back", 0];
      _actionId = player getVariable "cwr3_to_back_action_id";
      player setUserActionText [_actionId, localize "STR_cwr3_action_holster"];
    }];
    addUserActionEventHandler ["SwitchSecondary", "Activate", {
      _index = [player] call cwr3_fn_getCurrentWeaponIndex;
      player setVariable ["cwr3_prev_weapon", _index];
      player setVariable ["cwr3_weapon_on_back", 0];
      _actionId = player getVariable "cwr3_to_back_action_id";
      player setUserActionText [_actionId, localize "STR_cwr3_action_on_back"];
    }];
  };
};

// iterate each unit
cwr3_fn_discoverNewMen = {
  {
    if (_x isKindOf "man" && !(_x in cwr3_all_units) && _x != player) then {
//      diag_log format ["CWR3: discoverNewMan adding unit %1 to list", _x];
      cwr3_all_units pushBack _x;
      _x addEventHandler ["Killed", cwr3_fn_onUnitKilled];

      // can help, if unit is stucked, only for player side
      if (side _x == side player) then {
          [_x] call cwr3_fn_addGetOverAction;
      };
    };
  } forEach allUnits;
};

["itemAdd", ["menListUpdate", cwr3_fn_discoverNewMen, 15, "seconds"]] call BIS_fnc_loop;
