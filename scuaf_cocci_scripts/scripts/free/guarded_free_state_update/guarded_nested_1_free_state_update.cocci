virtual report

@free_script forall@
expression LOCK;
type TARGET_FUNC_RET_TYPE;
identifier TARGET_FUNC;

type OUTERMOST_STRUCT_TYPE;
OUTERMOST_STRUCT_TYPE *OUTERMOST_STRUCT_PTR;
identifier FREE_STRUCT_PTR;

identifier NEW_STATE;

position LOCK_POSITION;
position UNLOCK_POSITION;
position FREE_POSITION;
position STATE_UPDATE_POSITION;

identifier LOCK_FUNC    =~ "_lock|_trylock";
identifier UNLOCK_FUNC  =~ "_unlock";
identifier FREE_FUNC    =~ "kfree|kmem_cache_free|mm_page_free|mm_page_free_batched|free|kzfree|vfree|kvfree|kfree_sensitive|kvfree_sensitive|debugfs_remove|debugfs_remove_recursive|usb_free_urb|kmem_cache_destroy|mempool_destroy|dma_pool_destroy";
@@

TARGET_FUNC_RET_TYPE TARGET_FUNC(...){
... when exists, any
* LOCK_FUNC(LOCK)                                   @LOCK_POSITION
... when exists, any
* FREE_FUNC(OUTERMOST_STRUCT_PTR->FREE_STRUCT_PTR)  @FREE_POSITION
... when exists, any
OUTERMOST_STRUCT_PTR->FREE_STRUCT_PTR = NEW_STATE   @STATE_UPDATE_POSITION
... when exists, any
* UNLOCK_FUNC(LOCK)                                 @UNLOCK_POSITION
... when exists, any
}

//==========================================

@type_script depends on free_script forall@
type FREE_STRUCT_TYPE;
type free_script.OUTERMOST_STRUCT_TYPE;
identifier free_script.FREE_STRUCT_PTR;

position FREE_STRUCT_TYPE_POSITION;
@@

OUTERMOST_STRUCT_TYPE {
    ...
    FREE_STRUCT_TYPE FREE_STRUCT_PTR;         @FREE_STRUCT_TYPE_POSITION   
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

pos_state_update        << free_script.STATE_UPDATE_POSITION;

outermost_struct_type   << free_script.OUTERMOST_STRUCT_TYPE;
outermost_struct_ptr    << free_script.OUTERMOST_STRUCT_PTR;

free_struct_type        << type_script.FREE_STRUCT_TYPE;
free_struct_ptr         << free_script.FREE_STRUCT_PTR;
@@

import json

report = {}
report["report_class"] = "guarded_free_state_update" 
report["report_type"] = "guarded_nested_1_free_state_update" 
report["target_func_ret_type"] = target_func_ret_type
report["target_func"] = target_func
report["lock_func"] = lock_func
report["lock_position"] = pos_lock[0].__dict__["file"] + " +" + pos_lock[0].__dict__["line"]
report["lock"] = lock
report["free_func"] = free_func
report["free_position"] = pos_free[0].__dict__["file"] + " +" + pos_free[0].__dict__["line"]
report["outermost_struct_type"] = outermost_struct_type + " *"
report["outermost_struct_ptr"] = outermost_struct_ptr
report["free_struct_type"] = free_struct_type
report["free_struct_ptr"] = free_struct_ptr
report["state_update_position"] = pos_state_update[0].__dict__["file"] + " +" + pos_state_update[0].__dict__["line"]
report["unlock_func"] = unlock_func
report["unlock_position"] = pos_unlock[0].__dict__["file"] + " +" + pos_unlock[0].__dict__["line"]
report["types"] = [f"{outermost_struct_type}", f"{free_struct_type}"]

coccilib.report.print_report(pos_free[0], f"REPORT @{json.dumps(report)}")
