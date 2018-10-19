#ifndef SHOW_H
#define SHOW_H
#include <iostream>
#include <future>
#include "string.hpp"
#include "list.hpp"
#include "option.hpp"
#include "nat.hpp"
#include "type_checks.h"
#include "tuple.hpp"

using namespace Nat;
using namespace String;
using namespace List;
using namespace Option;
using namespace Tuple;

namespace Show {

    // nat -> string
    template<typename N=nat>
    typename std::enable_if_t<is_same_kind_v<N, nat>,  string>
    static show(N&& n) {
        return std::to_string(n);
    }

    // bool -> string
    template<typename B=bool>
    typename std::enable_if_t<is_same_kind_v<B, bool>,  string>
    static show(B&& b) {
        if (b) { return string("true"); }
        return string("false");;
    }

    // char -> string
    template<typename C=char>
    typename std::enable_if_t<is_same_kind_v<C, char>,  string>
    static show(C&& c) {
        return string(1, c);
    }

    // string -> string
    template<typename S=string>
    typename std::enable_if_t<is_same_kind_v<string, S>,  string>
    static show(S&& s) {
        return FWD(s);
    }

    // tuple -> string
    template<class TupType, size_t... I>
    static string show(const TupType& t, std::index_sequence<I...>)
    {
        std::stringstream ss;
        ss<< "(";
        (..., (ss << (I == 0? "" : ", ") << show(std::get<I>(t))));
        ss << ")";
        return ss.str();
    }
    template<class ...Args>
    static string show(const tuple<Args...>& t)
    {
        return show(t, std::make_index_sequence<sizeof...(Args)>());
    }

    // list<T> -> string
    template<typename L, typename T = typename std::remove_reference_t<L>::value_type>
	typename std::enable_if_t<is_same_kind_v<L, list<T>>, string>
	static show(L&& l) {
        std::stringstream ss;
        ss << "[";
        for(auto i = FWD(l.begin()); i != FWD(l.end()); ++i) {
            if (i != l.begin())
                ss << ", ";
            ss << show(*i);
        }
        ss << "]";
		return ss.str();
    }

    // Optional<T> -> string
    template<typename O, typename T = typename std::remove_reference_t<O>::value_type>
    typename std::enable_if_t<is_same_kind_v<O, option<T>>,  string>
    static show(O&& o) {
        if (o.has_value()) {
            return append(string("Some "), show(o.value()));
        }
        return string("None");
    }


}
#endif