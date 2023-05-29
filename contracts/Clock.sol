// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

uint constant SECONDS_PER_DAY = 24 * 60 * 60;
int constant OFFSET19700101 = 2440588;

contract Clock {
    uint private _timestamp;

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    function _daysFromDateConcatenated(uint256 date)  internal pure returns  (uint256 _days) {
        require(date >= 19710000);
        int256 _day = int256(date % 100);
        int256 _month = int256((date / 100) % 100);
        int256 _year = int256(date / 10000);
        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    function getNow() public view returns (uint) {
        if (_timestamp > 0) {
            return _timestamp;
        }
        return block.timestamp;
    }

    function getCurrentDate() public view returns (uint256 date) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(getNow() / SECONDS_PER_DAY);
        date = year * 10000 + month * 100 + day;
    }

    function getDaysFromNow(uint date) public view returns (uint256) {
        return _daysFromDateConcatenated(getCurrentDate()) - _daysFromDateConcatenated(date);
    }

    function setNow(uint timestamp) public {
        _timestamp = timestamp;
    }

    function setCurrentDate(uint date) public {
        setNow(_daysFromDateConcatenated(date) * SECONDS_PER_DAY);
    }
}