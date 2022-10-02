tmp_create_arrow = {
  _pos = param [0];
  _this = createVehicle ["VR_3DSelector_01_default_F", _pos, [], 0, "CAN_COLLIDE"];
//  _this setPosWorld [2224.47,7359.42,97.0966];
  _this setVectorDirAndUp [[0,1,0],[0,0,1]];
//  [_this, 0] remoteExec ['setFeatureType', 0, _this];
};

tmp_create_arrows_vehicle = {
  _veh = param [0];

  _veh setDir 0;

  _box = 0 boundingBoxReal _veh;
  _pos = position _veh;
  _x = _pos # 0;
  _y = _pos # 1;

  _a = _box # 0;
  _b = _box # 1;

  _dir = direction _veh;

  _sin = sin _dir;
  _cos = cos _dir;

  _x1 = _a # 0;
  _y1 = _a # 1;
  _x2 = _b # 0;
  _y2 = _b # 1;

  _pos1 = [_x + _x1, _y + _y1, 0];
  _pos2 = [_x + _x1, _y + _y2, 0];
  _pos3 = [_x + _x2, _y + _y2, 0];
  _pos4 = [_x + _x2, _y + _y1, 0];

//  [_pos1] call tmp_create_arrow;
[_pos2] call tmp_create_arrow;
[_pos3] call tmp_create_arrow;
//  [_pos4] call tmp_create_arrow;
_width = _x2 - _x1;
_radius = _width / 2;
_position = _y2 + _radius;
hint format ["width %1, radius %2, position %3", _width, _radius, _position];
};

cwr3_fnc_getVehicleFrontBackParams = {
  _bounds = param [0];
  _a = _bounds # 0;
  _b = _bounds # 1;
  _x1 = _a # 0;
  _y1 = _a # 1;
  _x2 = _b # 0;
  _y2 = _b # 1;

  _width = _x2 - _x1;
  _radius = _width / 2;
  _front = _y2; // + _radius;
  _back = _y1; // - _radius;

  [_width, _front, _back];
};

cwr3_fnc_getFrontPosition = {
  _vehicle = param [0];
  _distance = param [1];
  _pos = position _vehicle;
  _dir = direction _vehicle;
  _x = sin _dir * _distance + _pos # 0;
  _y = cos _dir * _distance + _pos # 1;
  [_x, _y, 0];
};

[] spawn {
  sleep 15;
  diag_log "CWR3Resistance: freeTankFromStuckInObject";

  _fn_unstuck_tank_from_tree = {
    _vehicle = param [0];
    _bounding = 0 boundingBoxReal _vehicle;
    _frontBack = [_bounding] call cwr3_fnc_getVehicleFrontBackParams;
    _radius = _frontBack # 0;
    _frontDist = _frontBack # 1;
    _counter = 0;
    while { true } do {
      // only for none player vehicles
      _spd = speed _vehicle;
      if (vehicle player != _vehicle && _spd > -0.2 && _spd < 0.2 && _spd != 0 && isEngineOn _vehicle && ! stopped _vehicle) then {
        if (_counter > 2) then {
          _dir = direction _vehicle;
          _pos = [_vehicle, _frontDist] call cwr3_fnc_getFrontPosition;
           // hmm, we have to set radius of 9 to get something, radius by boundaries does not work :(
          _objs = nearestTerrainObjects [_pos, ["TREE", "WALL"], 9];
//          [_pos] call tmp_create_arrow;
//          hint format ["objs: %1", _objs];
          if (count _objs > 0) then {
            {
              if (damage _x != 1) exitWith {
                _x setDamage 1;
                diag_log format ["CWR3Resistance: freeTankFromStuckInObject - destroying %1", _x];
              };
            } forEach _objs;
          };
          _counter = 0;
        } else {
          _counter = _counter + 1;
        };
      } else {
        _counter = 0;
      };

      sleep 1.5;
    };
  };

  {
    if (_x isKindOf "TANK") then {
      diag_log format ["CWR3Resistance: auto unstack from object for %1", _x];
      [_x] spawn _fn_unstuck_tank_from_tree;
    };
  } forEach vehicles;
};
