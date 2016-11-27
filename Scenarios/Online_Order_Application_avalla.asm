	asm Online_Order_Application_avalla
	import StandardLibrary
	
	signature:

	enum domain UseCase = { REGISTER | MAKEORDERS | ADDITEMS | DELETEITEMS | CANCELORDERS }
	domain InitialUseCase subsetof UseCase
	enum domain SystemState = { ABORTED | CANCELLED | EXECUTING | INIT | READY | TERMINATED }
	//INIT: the system has just been started
    //EXECUTING: a use case is running
    //ABORTED: a use case has been aborted, but system is operating
    //TERMINATED: the system shuts down
    //READY: a use case has been executed and the user can choose to run another use case
    //CANCELLED: the customer wants to stop the use case execution
	enum domain Flow = {REGISTER_BASIC | MAKEORDERS_BASIC | ADDITEMS_BASIC | DELETEITEMS_BASIC | CANCELORDERS_BASIC | REGISTER_SAF_01 | REGISTER_GAF_02 | MAKEORDERS_SAF_01 | MAKEORDERS_GAF_02 | ADDITEMS_SAF_01 | ADDITEMS_GAF_02 | DELETEITEMS_SAF_01 | DELETEITEMS_GAF_02 | CANCELORDERS_SAF_01 | CANCELORDERS_GAF_02}
	

	// use case selected by the user
    dynamic monitored useCaseChosen : InitialUseCase
    // state of execution 
    dynamic controlled currState: SystemState
    
    // triple for the current use case
    dynamic controlled currUseCase : UseCase
    dynamic controlled currFlow: Flow 
	dynamic controlled currStep: Integer
	
	// variables for the management of alternative flow
	dynamic controlled previousFlow: Flow
    dynamic controlled previousFlowStep: Integer
    
    // triple for the including use case
    dynamic controlled referenceUseCase: UseCase
    dynamic controlled referenceFlowStep: Integer
    dynamic controlled referenceFlow: Flow
        
    // information about the system state
    dynamic controlled zmessage : String
    controlled zzcurrUseCase : Prod (UseCase, Flow, Integer) -> SystemState
    controlled zzreferenceUseCase : Prod (UseCase, Flow, Integer) -> SystemState
    
    // variable for the selection of the global alternative flow
    dynamic controlled globalFlow: Flow 

	// function that returns the name of the specific basic flow depending on the name of the use case  
    static basicFlow: UseCase -> Flow
    
    // function that indicates the flow to move
    controlled jump:Prod(UseCase, Flow, Integer, Integer)->Rule
    // function that includes all the actions to perform if condition is true
    controlled thenAction:Prod(UseCase, Flow, Integer)->Rule
    // function that includes all the actions to perform if condition is false
    controlled elseAction:Prod(UseCase, Flow, Integer)->Rule
    
    //flag for the rule r_resume_step
    dynamic controlled resume : Boolean
	
	dynamic monitored the_credential_are_correct : Boolean
	dynamic monitored the_quantity_entered_isnt_negative : Boolean
	dynamic monitored the_quantity_of_the_product_has_not_been_updated : Boolean
	dynamic monitored login_page_is_visible : Boolean
	dynamic monitored the_user_is_register : Boolean
	dynamic monitored the_order_has_been_performed : Boolean
	dynamic monitored the_order_has_been_cancelled : Boolean
	dynamic monitored the_orders_manager_enters_cancel : Boolean
	dynamic monitored the_order_has_not_been_cancelled : Boolean
	dynamic monitored the_quantity_of_the_product_has_been_updated : Boolean
	dynamic monitored the_product_has_been_added : Boolean
	dynamic monitored the_system_is_idle : Boolean
	dynamic monitored the_product_has_not_been_added : Boolean
	dynamic monitored the_order_has_not_been_performed : Boolean
	dynamic monitored the_user_clickcancel : Boolean
	dynamic monitored the_amount_entered_isnt_negative : Boolean
	
	dynamic controlled the_system_updates_the_quantity_of_the_product : Boolean
	dynamic controlled the_orders_manager_selects_the_quantity_of_product_to_add : Boolean
	dynamic controlled the_user_selects_the_item_to_add : Boolean
	dynamic controlled the_system_searches_the_order_to_remove_from_the_list_of_orders : Boolean
	dynamic controlled the_user_enter_username_and_password_ : Boolean
	dynamic controlled the_system_cancels_the_order : Boolean
	dynamic controlled the_orders_manager_selects_the_quantity_of_each_product_to_order : Boolean
	dynamic controlled the_user_selects_the_quantity_of_item_to_add : Boolean
	dynamic controlled the_system_displays_an_error_message : Boolean
	dynamic controlled the_system_cancels_the_transaction : Boolean
	dynamic controlled the_system_adds_the_order_to_the_list_of_orders : Boolean
	dynamic controlled the_orders_manager_selects_the_products_to_order : Boolean
	dynamic controlled the_orders_manager_selects_the_order_to_remove : Boolean
	dynamic controlled the_orders_manager_selects_the_product_to_add : Boolean
	
		
		


    
definitions:
	
	domain InitialUseCase = {REGISTER, DELETEITEMS, ADDITEMS, CANCELORDERS, MAKEORDERS}
	
	// function that returns the name of the specific basic flow depending on the name of the use case
	function basicFlow ($uc in UseCase) =
		switch ($uc )
			case REGISTER : REGISTER_BASIC
			case MAKEORDERS : MAKEORDERS_BASIC
			case ADDITEMS : ADDITEMS_BASIC
			case DELETEITEMS : DELETEITEMS_BASIC
			case CANCELORDERS : CANCELORDERS_BASIC
		endswitch
	
	// rule that initializes the initial states of the machine at the beginning of each new 
	// use case execution
	rule r_initialize_machine =
		par
			currUseCase := useCaseChosen
			currFlow := basicFlow(useCaseChosen)
			currStep := 1
			previousFlow := basicFlow(useCaseChosen)
			referenceUseCase := useCaseChosen
			previousFlowStep := 1
			currState:=EXECUTING
			resume := false
		endpar 
		
	// rule that restores the execution of the inclusive use case 	
	rule r_restore_reference_use_case = 
		par
			currUseCase := referenceUseCase
			currFlow := referenceFlow
			currStep := referenceFlowStep
		endpar
		
	// function that diverts the basic flow onto an alternative flow
	// setting the parameters of the new alternative flow and saving the parameters of the reference flow	
	rule r_alternative_flow ($f in Flow) = 
		seq
			//save of current flow and current step values
			previousFlow:= currFlow
			previousFlowStep:= currStep
			currFlow:=$f 
			currStep:=1
			//function that diverts the flow through the alternative flow
			jump(currUseCase, previousFlow, previousFlowStep, currStep)
		endseq

	// function dedicated to a sentence-type condition check
	// it checks the condition, if the conditions has not been validated it diverts the
	// running flow calling the r_alternative_flow rule
	rule r_validates_that ($cond in Boolean, $f in Flow) =
		if (not($cond)) then
			r_alternative_flow[$f] 
		endif
	
	// function dedicated to a sentence-type conditional
	// it checks the condition, after there can be both then-action istructions and else-action istructions
	rule r_conditional ($cond in Boolean, $f in Flow) =
		if ($cond) then
			thenAction(currUseCase, currFlow, currStep) 
		else
			if(currFlow = $f )then
				elseAction(currUseCase, currFlow, currStep)
			else
				r_alternative_flow[$f] 
			endif	
		endif
		
	// function dedicated to a sentence-type include	
	// this function manipulates variables that control the inclusion of a use case
	// inside another use case
	rule r_include_use_case ($uc in UseCase)  =	
		seq
			referenceUseCase := currUseCase
			referenceFlowStep := currStep+1
			referenceFlow := currFlow
			currStep := 1
			currUseCase:=$uc 
			currFlow:=basicFlow(currUseCase)	
		endseq
			
	// function dedicated to a sentence-type abort
	// it changes the currState value in ABORTED in order to cut off the flow of execution
	rule r_abort =
		currState:=ABORTED	
	
	// function dedicated to a sentence-type resume
	// it resets the reference flow by making it start from the step passed by parameter
	rule r_resume_step($n in Integer) =
		par
			currFlow := previousFlow
			currStep := $n
			resume := true
		endpar 
		
	rule r_global_alternative ($cond in Boolean, $f in Flow) =
		if ($cond) then
			seq
				currState:=CANCELLED
				globalFlow:=$f 
			endseq	
		endif




		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_R_ss01_The_User_enter_username_and_password_ =
			the_user_enter_username_and_password_ := true
			
		//basic flow post conditions
		
		rule r_Register_postconditions =
			if (the_user_is_register) then
				par
					zmessage := "The user is register"
					currState:=READY
				endpar
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		//basic rules of specific alternative flow 01
		rule r_R_saf01_s01_The_system_displays_an_error_message =
			the_system_displays_an_error_message := true
			
					
			
					
		//specific alternative flow 01 post conditions
		
		rule r_register_specific_alternative_flow_01_postconditions =
			if (the_product_has_not_been_added) and (the_quantity_of_the_product_has_not_been_updated) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of specific alternative flow 01
		//basic rules of global alternative flow 02
					
		rule r_R_gaf02_s01_The_system_cancels_the_transaction =
			the_system_cancels_the_transaction := true
					
					
		//global alternative flow 02 post conditions
		
		rule r_register_global_alternative_flow_02_postconditions =
			if (the_product_has_not_been_added) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of global alternative flow 02
		
		//rule that manages the execution of each step of each flow
		
		rule r_register_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case REGISTER_BASIC:
						switch($s) 
							case 01:r_R_ss01_The_User_enter_username_and_password_[]
							case 02:r_validates_that [the_credential_are_correct,REGISTER_SAF_01]
							case 2:r_Register_postconditions[]
						endswitch
					case REGISTER_SAF_01:
						switch($s)
							case 01:r_R_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_register_specific_alternative_flow_01_postconditions[]
						endswitch 
					case REGISTER_GAF_02:
						switch($s)
							case 01:r_R_gaf02_s01_The_system_cancels_the_transaction[]
							case 02:r_abort[]
							case 3:r_register_global_alternative_flow_02_postconditions[]
						endswitch 
				endswitch
				zzcurrUseCase(currUseCase,currFlow,currStep):=currState
			endseq
	//rule that executes each step of the use case
					
		rule r_register_basic =
			if((currFlow = REGISTER_BASIC) and (currState = EXECUTING)) then
				seq
					r_register_exec_one_step[currStep,currFlow] 
				 	if ((currFlow = REGISTER_BASIC) and (resume = false)) then currStep := currStep + 1 endif
				 	r_global_alternative[the_user_clickcancel, REGISTER_GAF_02]
				endseq
		 	endif
		 
		 //use case main rule, evaluation of preconditions
		 rule r_register =
			if (login_page_is_visible) then
				r_register_basic[] 
			else
				par
					currState:=TERMINATED
					zmessage:="Evaluation of preconditions failed"
				endpar
			endif
		
		//main rule of specific alternative flow 01
					
		rule r_register_specific_alternative_flow_01 =
			if(currFlow = REGISTER_SAF_01) then
				seq
					r_register_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_register_global_alternative_flow_02 =
			if(currFlow = REGISTER_GAF_02) then
				seq
					r_register_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		
		// initialization of rules about launching of alternative and conditional flows
		rule r_init_register( $uc in UseCase) =
			jump($uc, REGISTER_BASIC, 02, 01) := <<r_register>>
				
				
				

		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_DI_ss01_The_Orders_Manager_selects_the_product_to_add =
			the_orders_manager_selects_the_product_to_add := true
			
		rule r_DI_ss02_The_Orders_Manager_selects_the_quantity_of_product_to_add =
			the_orders_manager_selects_the_quantity_of_product_to_add := true
			
		rule r_DI_ss04_The_system_updates_the_quantity_of_the_product =
			the_system_updates_the_quantity_of_the_product := true
			
		//basic flow post conditions
		
		rule r_Delete_Items_postconditions =
			if (the_product_has_been_added) and (the_quantity_of_the_product_has_been_updated) then
				par
					zmessage := "The product has been added.The quantity of the product has been updated."
					currState:=READY
				endpar
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		//basic rules of specific alternative flow 01
		rule r_DI_saf01_s01_The_system_displays_an_error_message =
			the_system_displays_an_error_message := true
			
					
			
					
		//specific alternative flow 01 post conditions
		
		rule r_delete_items_specific_alternative_flow_01_postconditions =
			if (the_product_has_not_been_added) and (the_quantity_of_the_product_has_not_been_updated) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of specific alternative flow 01
		//basic rules of global alternative flow 02
					
		rule r_DI_gaf02_s01_The_system_cancels_the_transaction =
			the_system_cancels_the_transaction := true
					
					
		//global alternative flow 02 post conditions
		
		rule r_delete_items_global_alternative_flow_02_postconditions =
			if (the_product_has_not_been_added) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of global alternative flow 02
		
		//rule that manages the execution of each step of each flow
		
		rule r_delete_items_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case DELETEITEMS_BASIC:
						switch($s) 
							case 01:r_DI_ss01_The_Orders_Manager_selects_the_product_to_add[]
							case 02:r_DI_ss02_The_Orders_Manager_selects_the_quantity_of_product_to_add[]
							case 03:r_validates_that [the_quantity_entered_isnt_negative, DELETEITEMS_SAF_01]
							case 04:r_DI_ss04_The_system_updates_the_quantity_of_the_product[]
							case 4:r_Delete_Items_postconditions[]
						endswitch
					case DELETEITEMS_SAF_01:
						switch($s)
							case 01:r_DI_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_delete_items_specific_alternative_flow_01_postconditions[]
						endswitch 
					case DELETEITEMS_GAF_02:
						switch($s)
							case 01:r_DI_gaf02_s01_The_system_cancels_the_transaction[]
							case 02:r_abort[]
							case 3:r_delete_items_global_alternative_flow_02_postconditions[]
						endswitch 
				endswitch
				zzcurrUseCase(currUseCase,currFlow,currStep):=currState
			endseq
	//rule that executes each step of the use case
					
		rule r_delete_items_basic =
			if((currFlow = DELETEITEMS_BASIC) and (currState = EXECUTING)) then
				seq
					r_delete_items_exec_one_step[currStep,currFlow] 
				 	if ((currFlow = DELETEITEMS_BASIC) and (resume = false)) then currStep := currStep + 1 endif
				 	r_global_alternative[the_orders_manager_enters_cancel, DELETEITEMS_GAF_02]
				endseq
		 	endif
		 
		 //use case main rule, evaluation of preconditions
		 rule r_delete_items =
			if (the_system_is_idle) then
				r_delete_items_basic[] 
			else
				par
					currState:=TERMINATED
					zmessage:="Evaluation of preconditions failed"
				endpar
			endif
		
		//main rule of specific alternative flow 01
					
		rule r_delete_items_specific_alternative_flow_01 =
			if(currFlow = DELETEITEMS_SAF_01) then
				seq
					r_delete_items_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_delete_items_global_alternative_flow_02 =
			if(currFlow = DELETEITEMS_GAF_02) then
				seq
					r_delete_items_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		
		// initialization of rules about launching of alternative and conditional flows
		rule r_init_delete_items( $uc in UseCase) =
			jump($uc, DELETEITEMS_BASIC, 03, 01) := <<r_delete_items_specific_alternative_flow_01>>
				
				
				

		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_AI_ss01_The_user_selects_the_item_to_add =
			the_user_selects_the_item_to_add := true
			
		rule r_AI_ss02_The_User_selects_the_quantity_of_item_to_add =
			the_user_selects_the_quantity_of_item_to_add := true
			
		rule r_AI_ss04_The_system_updates_the_quantity_of_the_product =
			the_system_updates_the_quantity_of_the_product := true
			
		//basic flow post conditions
		
		rule r_Add_Items_postconditions =
			if (the_product_has_been_added) and (the_quantity_of_the_product_has_been_updated) then
				par
					zmessage := "The product has been added.The quantity of the product has been updated."
					currState:=READY
				endpar
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		//basic rules of specific alternative flow 01
		rule r_AI_saf01_s01_The_system_displays_an_error_message =
			the_system_displays_an_error_message := true
			
					
			
					
		//specific alternative flow 01 post conditions
		
		rule r_add_items_specific_alternative_flow_01_postconditions =
			if (the_product_has_not_been_added) and (the_quantity_of_the_product_has_not_been_updated) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of specific alternative flow 01
		//basic rules of global alternative flow 02
					
		rule r_AI_gaf02_s01_The_system_cancels_the_transaction =
			the_system_cancels_the_transaction := true
					
					
		//global alternative flow 02 post conditions
		
		rule r_add_items_global_alternative_flow_02_postconditions =
			if (the_product_has_not_been_added) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of global alternative flow 02
		
		//rule that manages the execution of each step of each flow
		
		rule r_add_items_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case ADDITEMS_BASIC:
						switch($s) 
							case 01:r_AI_ss01_The_user_selects_the_item_to_add[]
							case 02:r_AI_ss02_The_User_selects_the_quantity_of_item_to_add[]
							case 03:r_validates_that [the_quantity_entered_isnt_negative, ADDITEMS_SAF_01]
							case 04:r_AI_ss04_The_system_updates_the_quantity_of_the_product[]
							case 4:r_Add_Items_postconditions[]
						endswitch
					case ADDITEMS_SAF_01:
						switch($s)
							case 01:r_AI_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_add_items_specific_alternative_flow_01_postconditions[]
						endswitch 
					case ADDITEMS_GAF_02:
						switch($s)
							case 01:r_AI_gaf02_s01_The_system_cancels_the_transaction[]
							case 02:r_abort[]
							case 3:r_add_items_global_alternative_flow_02_postconditions[]
						endswitch 
				endswitch
				zzcurrUseCase(currUseCase,currFlow,currStep):=currState
			endseq
	//rule that executes each step of the use case
					
		rule r_add_items_basic =
			if((currFlow = ADDITEMS_BASIC) and (currState = EXECUTING)) then
				seq
					r_add_items_exec_one_step[currStep,currFlow] 
				 	if ((currFlow = ADDITEMS_BASIC) and (resume = false)) then currStep := currStep + 1 endif
				 	r_global_alternative[the_user_clickcancel, ADDITEMS_GAF_02]
				endseq
		 	endif
		 
		 //use case main rule, evaluation of preconditions
		 rule r_add_items =
			if (the_system_is_idle) then
				r_add_items_basic[] 
			else
				par
					currState:=TERMINATED
					zmessage:="Evaluation of preconditions failed"
				endpar
			endif
		
		//main rule of specific alternative flow 01
					
		rule r_add_items_specific_alternative_flow_01 =
			if(currFlow = ADDITEMS_SAF_01) then
				seq
					r_add_items_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_add_items_global_alternative_flow_02 =
			if(currFlow = ADDITEMS_GAF_02) then
				seq
					r_add_items_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		
		// initialization of rules about launching of alternative and conditional flows
		rule r_init_add_items( $uc in UseCase) =
			jump($uc, ADDITEMS_BASIC, 03, 01) := <<r_add_items_specific_alternative_flow_01>>
				
				
				

		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_CO_ss01_The_Orders_Manager_selects_the_order_to_remove =
			the_orders_manager_selects_the_order_to_remove := true
			
		rule r_CO_ss02_The_system_searches_the_order_to_remove_from_the_list_of_orders =
			the_system_searches_the_order_to_remove_from_the_list_of_orders := true
			
		rule r_CO_ss03_The_system_cancels_the_order =
			the_system_cancels_the_order := true
			
		//basic flow post conditions
		
		rule r_Cancel_Orders_postconditions =
			if (the_order_has_been_cancelled) then
				par
					zmessage := "The order has been cancelled."
					currState:=READY
				endpar
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		//basic rules of specific alternative flow 01
		rule r_CO_saf01_s01_The_system_displays_an_error_message =
			the_system_displays_an_error_message := true
			
					
			
					
		//specific alternative flow 01 post conditions
		
		rule r_cancel_orders_specific_alternative_flow_01_postconditions =
			if (the_order_has_not_been_cancelled) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of specific alternative flow 01
		//basic rules of global alternative flow 02
					
		rule r_CO_gaf02_s01_The_system_cancels_the_transaction =
			the_system_cancels_the_transaction := true
					
					
		//global alternative flow 02 post conditions
		
		rule r_cancel_orders_global_alternative_flow_02_postconditions =
			if (the_order_has_not_been_cancelled) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of global alternative flow 02
		
		//rule that manages the execution of each step of each flow
		
		rule r_cancel_orders_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case CANCELORDERS_BASIC:
						switch($s) 
							case 01:r_CO_ss01_The_Orders_Manager_selects_the_order_to_remove[]
							case 02:r_CO_ss02_The_system_searches_the_order_to_remove_from_the_list_of_orders[]
							case 03:r_CO_ss03_The_system_cancels_the_order[]
							case 04:r_validates_that [the_order_has_been_cancelled, CANCELORDERS_SAF_01]
							case 4:r_Cancel_Orders_postconditions[]
						endswitch
					case CANCELORDERS_SAF_01:
						switch($s)
							case 01:r_CO_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_cancel_orders_specific_alternative_flow_01_postconditions[]
						endswitch 
					case CANCELORDERS_GAF_02:
						switch($s)
							case 01:r_CO_gaf02_s01_The_system_cancels_the_transaction[]
							case 02:r_abort[]
							case 3:r_cancel_orders_global_alternative_flow_02_postconditions[]
						endswitch 
				endswitch
				zzcurrUseCase(currUseCase,currFlow,currStep):=currState
			endseq
	//rule that executes each step of the use case
					
		rule r_cancel_orders_basic =
			if((currFlow = CANCELORDERS_BASIC) and (currState = EXECUTING)) then
				seq
					r_cancel_orders_exec_one_step[currStep,currFlow] 
				 	if ((currFlow = CANCELORDERS_BASIC) and (resume = false)) then currStep := currStep + 1 endif
				 	r_global_alternative[the_orders_manager_enters_cancel, CANCELORDERS_GAF_02]
				endseq
		 	endif
		 
		 //use case main rule, evaluation of preconditions
		 rule r_cancel_orders =
			if (the_system_is_idle) then
				r_cancel_orders_basic[] 
			else
				par
					currState:=TERMINATED
					zmessage:="Evaluation of preconditions failed"
				endpar
			endif
		
		//main rule of specific alternative flow 01
					
		rule r_cancel_orders_specific_alternative_flow_01 =
			if(currFlow = CANCELORDERS_SAF_01) then
				seq
					r_cancel_orders_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_cancel_orders_global_alternative_flow_02 =
			if(currFlow = CANCELORDERS_GAF_02) then
				seq
					r_cancel_orders_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		
		// initialization of rules about launching of alternative and conditional flows
		rule r_init_cancel_orders( $uc in UseCase) =
			jump($uc, CANCELORDERS_BASIC, 04, 01) := <<r_cancel_orders_specific_alternative_flow_01>>
				
				
				

		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_MO_ss01_The_Orders_Manager_selects_the_products_to_order =
			the_orders_manager_selects_the_products_to_order := true
			
		rule r_MO_ss02_The_Orders_Manager_selects_the_quantity_of_each_product_to_order =
			the_orders_manager_selects_the_quantity_of_each_product_to_order := true
			
		rule r_MO_ss04_The_system_adds_the_order_to_the_list_of_orders =
			the_system_adds_the_order_to_the_list_of_orders := true
			
		//basic flow post conditions
		
		rule r_Make_Orders_postconditions =
			if (the_order_has_been_performed) then
				par
					zmessage := "The order has been performed."
					currState:=READY
				endpar
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		//basic rules of specific alternative flow 01
		rule r_MO_saf01_s01_The_system_displays_an_error_message =
			the_system_displays_an_error_message := true
			
					
			
					
		//specific alternative flow 01 post conditions
		
		rule r_make_orders_specific_alternative_flow_01_postconditions =
			if (the_order_has_not_been_performed) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of specific alternative flow 01
		//basic rules of global alternative flow 02
					
		rule r_MO_gaf02_s01_The_system_cancels_the_transaction =
			the_system_cancels_the_transaction := true
					
					
		//global alternative flow 02 post conditions
		
		rule r_make_orders_global_alternative_flow_02_postconditions =
			if (the_order_has_not_been_performed) then
				currState:=READY
			else
				par
					zmessage := "The system is out of service"
					currState:=TERMINATED
				endpar
			endif
		
		//end of global alternative flow 02
		
		//rule that manages the execution of each step of each flow
		
		rule r_make_orders_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case MAKEORDERS_BASIC:
						switch($s) 
							case 01:r_MO_ss01_The_Orders_Manager_selects_the_products_to_order[]
							case 02:r_MO_ss02_The_Orders_Manager_selects_the_quantity_of_each_product_to_order[]
							case 03:r_validates_that [the_amount_entered_isnt_negative, MAKEORDERS_SAF_01]
							case 04:r_MO_ss04_The_system_adds_the_order_to_the_list_of_orders[]
							case 4:r_Make_Orders_postconditions[]
						endswitch
					case MAKEORDERS_SAF_01:
						switch($s)
							case 01:r_MO_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_make_orders_specific_alternative_flow_01_postconditions[]
						endswitch 
					case MAKEORDERS_GAF_02:
						switch($s)
							case 01:r_MO_gaf02_s01_The_system_cancels_the_transaction[]
							case 02:r_abort[]
							case 3:r_make_orders_global_alternative_flow_02_postconditions[]
						endswitch 
				endswitch
				zzcurrUseCase(currUseCase,currFlow,currStep):=currState
			endseq
	//rule that executes each step of the use case
					
		rule r_make_orders_basic =
			if((currFlow = MAKEORDERS_BASIC) and (currState = EXECUTING)) then
				seq
					r_make_orders_exec_one_step[currStep,currFlow] 
				 	if ((currFlow = MAKEORDERS_BASIC) and (resume = false)) then currStep := currStep + 1 endif
				 	r_global_alternative[the_orders_manager_enters_cancel, MAKEORDERS_GAF_02]
				endseq
		 	endif
		 
		 //use case main rule, evaluation of preconditions
		 rule r_make_orders =
			if (the_user_is_register) then
				r_make_orders_basic[] 
			else
				par
					currState:=TERMINATED
					zmessage:="Evaluation of preconditions failed"
				endpar
			endif
		
		//main rule of specific alternative flow 01
					
		rule r_make_orders_specific_alternative_flow_01 =
			if(currFlow = MAKEORDERS_SAF_01) then
				seq
					r_make_orders_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_make_orders_global_alternative_flow_02 =
			if(currFlow = MAKEORDERS_GAF_02) then
				seq
					r_make_orders_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		
		// initialization of rules about launching of alternative and conditional flows
		rule r_init_make_orders( $uc in UseCase) =
			jump($uc, MAKEORDERS_BASIC, 03, 01) := <<r_make_orders_specific_alternative_flow_01>>
				
				
				



	
	//definition of the main rule of the program
	main rule r_main =
		par
			//If the status of the machine is init, that is the execution has just begun, r_init rules
			//are called, which initialize all the rules belonging to the use cases.
			
			if (currState = INIT) then
				seq
					r_init_register[REGISTER] 
					r_init_make_orders[MAKEORDERS] 
					r_init_add_items[ADDITEMS] 
					r_init_delete_items[DELETEITEMS] 
					r_init_cancel_orders[CANCELORDERS] 
					currState := READY	
				endseq
			endif
			
			// After the INIT phase, the state of the system becomes READY
			// At this point the user can select the use case to execute
			if (currState = READY) then
		        seq 
					r_initialize_machine[]
					switch (useCaseChosen) // launch of the principal rule of the use case chosen
						case REGISTER : r_register[]
						case DELETEITEMS : r_delete_items[]
						case ADDITEMS : r_add_items[]
						case CANCELORDERS : r_cancel_orders[]
						case MAKEORDERS : r_make_orders[]
					endswitch
				endseq	
			endif
			
			// choice of the correct rule to execute according the current flow and the current use case 
			// during the execution of the program
			if ((currState = EXECUTING) or (currState = ABORTED)) then
				switch (currUseCase)
					case REGISTER :
						switch(currFlow)
							case REGISTER_BASIC: r_register_basic[]
							case REGISTER_SAF_01: r_register_specific_alternative_flow_01[]
							case REGISTER_GAF_02: r_register_global_alternative_flow_02[]
						endswitch 
					case MAKEORDERS :
						switch(currFlow)
							case MAKEORDERS_BASIC: r_make_orders_basic[]
							case MAKEORDERS_SAF_01: r_make_orders_specific_alternative_flow_01[]
							case MAKEORDERS_GAF_02: r_make_orders_global_alternative_flow_02[]
						endswitch 
					case ADDITEMS :
						switch(currFlow)
							case ADDITEMS_BASIC: r_add_items_basic[]
							case ADDITEMS_SAF_01: r_add_items_specific_alternative_flow_01[]
							case ADDITEMS_GAF_02: r_add_items_global_alternative_flow_02[]
						endswitch 
					case DELETEITEMS :
						switch(currFlow)
							case DELETEITEMS_BASIC: r_delete_items_basic[]
							case DELETEITEMS_SAF_01: r_delete_items_specific_alternative_flow_01[]
							case DELETEITEMS_GAF_02: r_delete_items_global_alternative_flow_02[]
						endswitch 
					case CANCELORDERS :
						switch(currFlow)
							case CANCELORDERS_BASIC: r_cancel_orders_basic[]
							case CANCELORDERS_SAF_01: r_cancel_orders_specific_alternative_flow_01[]
							case CANCELORDERS_GAF_02: r_cancel_orders_global_alternative_flow_02[]
						endswitch 
				endswitch	
			endif
		
			// in case of a global alternative flow it must be set the right current flow in order to run 
			// the rule relating to the correct global alternative flow
			if (currState = CANCELLED) then
				par
					switch (globalFlow)
						case REGISTER_GAF_02:
							seq
								currFlow:=REGISTER_GAF_02
								currUseCase:=REGISTER
				 				currStep:=1
				 			endseq	
						case MAKEORDERS_GAF_02:
							seq
								currFlow:=MAKEORDERS_GAF_02
								currUseCase:=MAKEORDERS
				 				currStep:=1
				 			endseq	
						case ADDITEMS_GAF_02:
							seq
								currFlow:=ADDITEMS_GAF_02
								currUseCase:=ADDITEMS
				 				currStep:=1
				 			endseq	
						case DELETEITEMS_GAF_02:
							seq
								currFlow:=DELETEITEMS_GAF_02
								currUseCase:=DELETEITEMS
				 				currStep:=1
				 			endseq	
						case CANCELORDERS_GAF_02:
							seq
								currFlow:=CANCELORDERS_GAF_02
								currUseCase:=CANCELORDERS
				 				currStep:=1
				 			endseq	
					endswitch
					currState:=EXECUTING
				endpar
			endif			
		endpar
	

default init initial_state:
function currState = INIT
function currStep = 1
function previousFlowStep = 1
	
