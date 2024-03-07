virtual report

@use_script forall@ 
expression LOCK;

type TARGET_FUNC_RET_TYPE;
identifier TARGET_FUNC;

type OUTERMOST_STRUCT_TYPE;
OUTERMOST_STRUCT_TYPE *OUTERMOST_STRUCT_PTR;
identifier FIELD_STRUCT_PTR;

identifier USE_STRUCT_PTR;
identifier FPTR;

identifier LOCK_FUNC    =~ "_lock|_trylock";
identifier UNLOCK_FUNC  =~ "_unlock";

position FPTR_CALL_POSITION;
position LOCK_POSITION;
position UNLOCK_POSITION;
@@

TARGET_FUNC_RET_TYPE TARGET_FUNC(...){
... when exists, any
* LOCK_FUNC(LOCK)                                                   @LOCK_POSITION
... when exists, any
* OUTERMOST_STRUCT_PTR->FIELD_STRUCT_PTR->USE_STRUCT_PTR->FPTR(...) @FPTR_CALL_POSITION
... when exists, any
* UNLOCK_FUNC(LOCK)                                                 @UNLOCK_POSITION
... when exists, any
}

//==========================================

@field_struct_type_script depends on use_script forall@
type FIELD_STRUCT_TYPE;
type use_script.OUTERMOST_STRUCT_TYPE;
identifier use_script.FIELD_STRUCT_PTR;

position FIELD_STRUCT_TYPE_POSITION;
@@

OUTERMOST_STRUCT_TYPE {
    ...
    FIELD_STRUCT_TYPE *FIELD_STRUCT_PTR;     @FIELD_STRUCT_TYPE_POSITION   
    ...
}

//==========================================

@use_struct_type_script depends on use_script forall@
type USE_STRUCT_TYPE;
type field_struct_type_script.FIELD_STRUCT_TYPE;
identifier use_script.USE_STRUCT_PTR;

position USE_STRUCT_TYPE_POSITION;
@@

FIELD_STRUCT_TYPE {
    ...
    USE_STRUCT_TYPE USE_STRUCT_PTR;         @USE_STRUCT_TYPE_POSITION   
    ...
}

//==========================================

@script:python depends on report@
target_func_ret_type    << use_script.TARGET_FUNC_RET_TYPE;
target_func             << use_script.TARGET_FUNC;

outermost_struct_type   << use_script.OUTERMOST_STRUCT_TYPE;
outermost_struct_ptr    << use_script.OUTERMOST_STRUCT_PTR;
field_struct_type       << field_struct_type_script.FIELD_STRUCT_TYPE;
field_struct_ptr        << use_script.FIELD_STRUCT_PTR;
use_struct_type         << use_struct_type_script.USE_STRUCT_TYPE;
use_struct_ptr          << use_script.USE_STRUCT_PTR;
fptr                    << use_script.FPTR;
pos_fptr_call           << use_script.FPTR_CALL_POSITION;

lock_func               << use_script.LOCK_FUNC;
pos_lock                << use_script.LOCK_POSITION;
unlock_func             << use_script.UNLOCK_FUNC;
pos_unlock              << use_script.UNLOCK_POSITION;
lock                    << use_script.LOCK;
@@

import json

report = {}
report["report_class"] = "guarded_fptr_call" 
report["report_type"] = "guarded_nested_2_fptr_call" 
report["target_func_ret_type"] = target_func_ret_type
report["target_func"] = target_func
report["lock_func"] = lock_func
report["lock_position"] = pos_lock[0].__dict__["file"] + " +" + pos_lock[0].__dict__["line"]
report["lock"] = lock
report["outermost_struct_type"] = outermost_struct_type + " *"
report["outermost_struct_ptr"] = outermost_struct_ptr
report["field_struct_type"] = field_struct_type + " *"
report["field_struct_ptr"] = field_struct_ptr
report["use_struct_type"] = use_struct_type
report["use_struct_ptr"] = use_struct_ptr
report["fptr"] = fptr
report["fptr_call_position"] = pos_fptr_call[0].__dict__["file"] + " +" + pos_fptr_call[0].__dict__["line"]
report["unlock_func"] = unlock_func
report["unlock_position"] = pos_unlock[0].__dict__["file"] + " +" + pos_unlock[0].__dict__["line"]
report["types"] = [f"{outermost_struct_type}", f"{field_struct_type}", f"{use_struct_type}"]

coccilib.report.print_report(pos_fptr_call[0], f"REPORT @{json.dumps(report)}")
