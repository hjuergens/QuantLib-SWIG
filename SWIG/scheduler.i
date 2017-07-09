
/*
 Copyright (C) 2000, 2001, 2002, 2003 RiskMap srl
 Copyright (C) 2007, 2008 StatPro Italia srl

 This file is part of QuantLib, a free-software/open-source library
 for financial quantitative analysts and developers - http://quantlib.org/

 QuantLib is free software: you can redistribute it and/or modify it
 under the terms of the QuantLib license.  You should have received a
 copy of the license along with this program; if not, please email
 <quantlib-dev@lists.sf.net>. The license is also available online at
 <http://quantlib.org/license.shtml>.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
*/

#ifndef quantlib_scheduler_i
#define quantlib_scheduler_i

%include date.i
%include calendars.i
%include types.i

%{
using QuantLib::Schedule;
using QuantLib::DateGeneration;
%}

%define QL_TYPECHECK_BUSINESSDAYCONVENTION       5210    %enddef
%define QL_TYPECHECK_PERIOD				         5220    %enddef

struct DateGeneration {
    enum Rule { Backward, Forward,
                Zero, ThirdWednesday,
                Twentieth, TwentiethIMM,
                OldCDS, CDS, CDS2015 };
};

#if defined(SWIGRUBY)
%mixin Schedule "Enumerable";
#endif
class Schedule {
    #if defined(SWIGPYTHON) || defined(SWIGRUBY)
    %rename(__len__)       size;
    %ignore                date;
    #endif
    #if defined(SWIGRUBY)
    %rename("isRegular?")  isRegular;
    #elif defined(SWIGMZSCHEME) || defined(SWIGGUILE)
    %rename("is-regular?") isRegular;
    #endif
  public:

	#if defined(SWIGPYTHON)
	%typemap(in) boost::optional<BusinessDayConvention> %{
		if($input == Py_None)
			$1 = boost::none;
		else
			$1 = (BusinessDayConvention) PyLong_AsSize_t($input);
	%}
	%typecheck (QL_TYPECHECK_BUSINESSDAYCONVENTION) boost::optional<BusinessDayConvention> {
	if (PyLong_Check($input) || Py_None == $input) 
		$1 = 1;
	else
		$1 = 0;
	}
	%typemap(in) boost::optional<Period> %{
		if($input == Py_None)
			$1 = boost::none;
		else
		{
			Period *temp;
			if (!SWIG_IsOK(SWIG_ConvertPtr($input,(void **) &temp, $descriptor(Period*),0)))
				SWIG_exception_fail(SWIG_TypeError, "in method '$symname', expecting type Period");
			$1 = (boost::optional<Period>) *temp;
		}
	%}
	%typecheck (QL_TYPECHECK_PERIOD) boost::optional<Period> {
		if($input == Py_None)
			$1 = 1;
		else {
			Period *temp;
			int res = SWIG_ConvertPtr($input,(void **) &temp, $descriptor(Period*),0);
			$1 = SWIG_IsOK(res) ? 1 : 0;
		}
		
	}
	Schedule(const std::vector<Date>&,
			 const Calendar& calendar = NullCalendar(),
			 const BusinessDayConvention
								convention = Unadjusted,
			 boost::optional<BusinessDayConvention>
				 terminationDateConvention = boost::none,
			 const boost::optional<Period> tenor = boost::none);
	#else
	Schedule(const std::vector<Date>&,
		 const Calendar& calendar = NullCalendar(),
		 const BusinessDayConvention 
							convention = Unadjusted);
	#endif
    Schedule(const Date& effectiveDate,
             const Date& terminationDate,
             const Period& tenor,
             const Calendar& calendar,
             BusinessDayConvention convention,
             BusinessDayConvention terminationDateConvention,
             DateGeneration::Rule rule,
             bool endOfMonth,
             const Date& firstDate = Date(),
             const Date& nextToLastDate = Date());
    Schedule();
    Size size() const;
    Date date(Size i) const;
    bool isRegular(Size i) const;
    Schedule until(Date truncationDate) const;
    %extend {
        #if defined(SWIGPYTHON) || defined(SWIGRUBY)
        Date __getitem__(Integer i) {
            Integer size_ = static_cast<Integer>(self->size());
            if (i>=0 && i<size_) {
                return self->date(i);
            } else if (i<0 && -i<=size_) {
                return self->date(size_+i);
            } else {
                throw std::out_of_range("schedule index out of range");
            }
        }
        #endif
        #if defined(SWIGRUBY)
        void each() {
            for (Size i=0; i<self->size(); i++) {
                Date* d = new Date(self->date(i));
                rb_yield(SWIG_NewPointerObj((void *) d,
                                            $descriptor(Date *), 1));
            }
        }
        #elif defined(SWIGMZSCHEME)
        void for_each(Scheme_Object* proc) {
            for (Size i=0; i<self->size(); i++) {
                Date* d = new Date(self->date(i));
                Scheme_Object* x =
                    SWIG_NewPointerObj(d, $descriptor(Date *), 1);
                scheme_apply(proc,1,&x);
            }
        }
        #elif defined(SWIGGUILE)
        void for_each(SCM proc) {
            for (Size i=0; i<self->size(); i++) {
                Date* d = new Date(self->date(i));
                SCM x = SWIG_NewPointerObj(d, $descriptor(Date *), 1);
                gh_call1(proc,x);
            }
        }
        %scheme%{
            (define (Schedule-map s f)
              (let ((results '()))
                (Schedule-for-each s (lambda (d)
                                      (set! results (cons (f d) results))))
                (reverse results)))
            (export Schedule-map)
        %}
        #endif
    }
};


#endif
