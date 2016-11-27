	module Make_Orders
	import StandardLibrary
	import Online_Order_Application_Common
	export *
	
	
	signature:
	
	dynamic monitored the_order_has_not_been_performed : Boolean
	dynamic monitored the_user_is_register : Boolean
	dynamic monitored the_order_has_been_performed : Boolean
	dynamic monitored the_amount_entered_isnt_negative : Boolean
	dynamic monitored the_orders_manager_enters_cancel : Boolean
	
	dynamic controlled the_system_displays_an_error_message : Boolean
	dynamic controlled the_system_cancels_the_transaction : Boolean
	dynamic controlled the_system_adds_the_order_to_the_list_of_orders : Boolean
	dynamic controlled the_orders_manager_selects_the_products_to_order : Boolean
	dynamic controlled the_orders_manager_selects_the_quantity_of_each_product_to_order : Boolean
	
		
	
		

	definitions:
		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_ss01_The_Orders_Manager_selects_the_products_to_order =
			the_orders_manager_selects_the_products_to_order := true
			
		rule r_ss02_The_Orders_Manager_selects_the_quantity_of_each_product_to_order =
			the_orders_manager_selects_the_quantity_of_each_product_to_order := true
			
		rule r_ss04_The_system_adds_the_order_to_the_list_of_orders =
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
		rule r_saf01_s01_The_system_displays_an_error_message =
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
					
		rule r_gaf02_s01_The_system_cancels_the_transaction =
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
		
		rule r_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case MAKEORDERS_BASIC:
						switch($s) 
							case 01:r_ss01_The_Orders_Manager_selects_the_products_to_order[]
							case 02:r_ss02_The_Orders_Manager_selects_the_quantity_of_each_product_to_order[]
							case 03:r_validates_that [the_amount_entered_isnt_negative, MAKEORDERS_SAF_01]
							case 04:r_ss04_The_system_adds_the_order_to_the_list_of_orders[]
							case 5:r_Make_Orders_postconditions[]
						endswitch
					case MAKEORDERS_SAF_01:
						switch($s)
							case 01:r_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_make_orders_specific_alternative_flow_01_postconditions[]
						endswitch 
					case MAKEORDERS_GAF_02:
						switch($s)
							case 01:r_gaf02_s01_The_system_cancels_the_transaction[]
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
					r_exec_one_step[currStep,currFlow] 
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
					r_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_make_orders_global_alternative_flow_02 =
			if(currFlow = MAKEORDERS_GAF_02) then
				seq
					r_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		

		// initialization of rules about launching of alternative and conditional flows
		rule r_init_make_orders( $uc in UseCase) =
			jump($uc, MAKEORDERS_BASIC, 03, 01) := <<r_make_orders_specific_alternative_flow_01>>
				
				
				
