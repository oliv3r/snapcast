/***
    This file is part of snapcast
    Copyright (C) 2014-2020  Johannes Pohl

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
***/

#pragma once


// local headers
#include "common/json.hpp"

// standard headers
#include <map>
#include <string>


using json = nlohmann::json;

namespace streamreader
{

// scheme:[//[user:password@]host[:port]][/]path[?query][#fragment]
struct StreamUri
{
    StreamUri(const std::string& uri);
    std::string uri;
    std::string scheme;
    /*	struct Authority
            {
                    std::string username;
                    std::string password;
                    std::string host;
                    size_t port;
            };
            Authority authority;
    */
    std::string host;
    std::string path;
    std::map<std::string, std::string> query;
    std::string fragment;

    std::string id() const;
    json toJson() const;
    std::string getQuery(const std::string& key, const std::string& def = "") const;

    void parse(const std::string& streamUri);
    std::string toString() const;
};

} // namespace streamreader
