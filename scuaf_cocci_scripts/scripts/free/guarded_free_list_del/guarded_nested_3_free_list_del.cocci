virtual report

@free_script forall@
expression LOCK;

type TARGET_FUNC_RET_TYPE;
identifier TARGET_FUNC;

type OUTERMOST_STRUCT_TYPE;
OUTERMOST_STRUCT_TYPE *OUTERMOST_STRUCT_PTR;
identifier FIELD_STRUCT_PTR;
identifier FIELD_STRUCT_PTR_2;
identifier FREE_STRUCT_PTR;

position LOCK_POSITION;
position UNLOCK_POSITION;
position FREE_POSITION;
position LIST_DEL_POSITION;

identifier LOCK_FUNC    =~ "_lock|_trylock";
identifier UNLOCK_FUNC  =~ "_unlock";
identifier FREE_FUNC    =~ "kfree|kmem_cache_free|mm_page_free|mm_page_free_batched|free|kzfree|vfree|kvfree|kfree_sensitive|kvfree_sensitive|debugfs_remove|debugfs_remove_recursive|usb_free_urb|kmem_cache_destroy|mempool_destroy|dma_pool_destroy";
identifier LIST_DEL_FUNC=~ "list_del";
@@

TARGET_FUNC_RET_TYPE TARGET_FUNC(...){
... when exists, any
* LOCK_FUNC(LOCK)                                                                           @LOCK_POSITION
... when exists, any
* FREE_FUNC(OUTERMOST_STRUCT_PTR->FIELD_STRUCT_PTR->FIELD_STRUCT_PTR_2->FREE_STRUCT_PTR)    @FREE_POSITION
... when exists, any
* LIST_DEL_FUNC(...)                                                                        @LIST_DEL_POSITION
... when exists, any
* UNLOCK_FUNC(LOCK)                                                                         @UNLOCK_POSITION
... when exists, any
}

//==========================================

@field_struct_type_script depends on free_script forall@
type FIELD_STRUCT_TYPE;
type free_script.OUTERMOST_STRUCT_TYPE;
identifier free_script.FIELD_STRUCT_PTR;

position FIELD_STRUCT_TYPE_POSITION;
@@

OUTERMOST_STRUCT_TYPE {
    ...
    FIELD_STRUCT_TYPE *FIELD_STRUCT_PTR;         @FIELD_STRUCT_TYPE_POSITION   
    ...
};

//==========================================

@field_struct_type_script_2 depends on free_script forall@
type FIELD_STRUCT_TYPE_2;
type field_struct_type_script.FIELD_STRUCT_TYPE;
identifier free_script.FIELD_STRUCT_PTR_2;

position FIELD_STRUCT_TYPE_2_POSITION;
@@

FIELD_STRUCT_TYPE {
    ...
    FIELD_STRUCT_TYPE_2 *FIELD_STRUCT_PTR_2;    @FIELD_STRUCT_TYPE_2_POSITION
    ...
};

//==========================================

@free_struct_type_script depends on free_script forall@
type FREE_STRUCT_TYPE;
type field_struct_type_script_2.FIELD_STRUCT_TYPE_2;
identifier free_script.FREE_STRUCT_PTR;

position FREE_STRUCT_TYPE_POSITION;
@@

FIELD_STRUCT_TYPE_2 {
    ...
    FREE_STRUCT_TYPE FREE_STRUCT_PTR;           @FREE_STRUCT_TYPE_POSITION   
    ...
};

//==========================================

@script:python depends on report@
target_func_ret_type    << free_script.TARGET_FUNC_RET_TYPE;
target_func             << free_script.TARGET_FUNC;

lock_func               << free_script.LOCK_FUNC;
pos_lock                << free_script.LOCK_POSITION;
unlock_func             << free_script.UNLOCK_FUNC;
pos_unlock              << free_script.UNLOCK_POSITION;
lock                    << free_script.LOCK;

free_func               << free_script.FREE_FUNC;
pos_free                << free_script.FREE_POSITION;

outermost_struct_type   << free_script.OUTERMOST_STRUCT_TYPE;
outermost_struct_ptr    << free_script.OUTERMOST_STRUCT_PTR;

field_struct_type       << field_struct_type_script.FIELD_STRUCT_TYPE;
field_struct_ptr        << free_script.FIELD_STRUCT_PTR;
field_struct_type_2     << field_struct_type_script_2.FIELD_STRUCT_TYPE_2;
field_struct_ptr_2      << free_script.FIELD_STRUCT_PTR_2;
free_struct_type        << free_struct_type_script.FREE_STRUCT_TYPE;
free_struct_ptr         << free_script.FREE_STRUCT_PTR;
list_del_func           << free_script.LIST_DEL_FUNC;
pos_list_del            << free_script.LIST_DEL_POSITION;
@@

import json

report = {}
report["report_class"] = "guarded_free_list_del" 
report["report_type"] = "guarded_nested_3_free_list_del" 
report["target_func_ret_type"] = target_func_ret_type
report["target_func"] = target_func
report["lock_func"] = lock_func
report["lock_position"] = pos_lock[0].__dict__["file"] + " +" + pos_lock[0].__dict__["line"]
report["lock"] = lock
report["free_func"] = free_func
report["free_position"] = pos_free[0].__dict__["file"] + " +" + pos_free[0].__dict__["line"]
report["outermost_struct_type"] = outermost_struct_type + " *"
report["outermost_struct_ptr"] = outermost_struct_ptr
report["field_struct_type"] = field_struct_type + " *"
report["field_struct_ptr"] = field_struct_ptr
report["field_struct_type_2"] = field_struct_type_2 + " *"
report["field_struct_ptr_2"] = field_struct_ptr_2
report["free_struct_type"] = free_struct_type
report["free_struct_ptr"] = free_struct_ptr
report["list_del_position"] = pos_list_del[0].__dict__["file"] + " +" + pos_list_del[0].__dict__["line"]
report["unlock_func"] = unlock_func
report["unlock_position"] = pos_unlock[0].__dict__["file"] + " +" + pos_unlock[0].__dict__["line"]
report["types"] = [f"{outermost_struct_type}", f"{field_struct_type}", f"{field_struct_type_2}", f"{free_struct_type}"]

coccilib.report.print_report(pos_free[0], f"REPORT @{json.dumps(report)}")
