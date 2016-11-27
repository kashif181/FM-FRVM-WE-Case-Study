	module Cancel_Orders
	import StandardLibrary
	import Online_Order_Application_Common
	export *
	
	
	signature:
	
	dynamic monitored the_order_has_not_been_cancelled : Boolean
	dynamic monitored the_system_is_idle : Boolean
	dynamic monitored the_order_has_been_cancelled : Boolean
	dynamic monitored the_orders_manager_enters_cancel : Boolean
	
	dynamic controlled the_system_displays_an_error_message : Boolean
	dynamic controlled the_system_cancels_the_transaction : Boolean
	dynamic controlled the_system_searches_the_order_to_remove_from_the_list_of_orders : Boolean
	dynamic controlled the_orders_manager_selects_the_order_to_remove : Boolean
	dynamic controlled the_system_cancels_the_order : Boolean
	
		
	
		

	definitions:
		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_ss01_The_Orders_Manager_selects_the_order_to_remove =
			the_orders_manager_selects_the_order_to_remove := true
			
		rule r_ss02_The_system_searches_the_order_to_remove_from_the_list_of_orders =
			the_system_searches_the_order_to_remove_from_the_list_of_orders := true
			
		rule r_ss03_The_system_cancels_the_order =
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
		rule r_saf01_s01_The_system_displays_an_error_message =
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
					
		rule r_gaf02_s01_The_system_cancels_the_transaction =
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
		
		rule r_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case CANCELORDERS_BASIC:
						switch($s) 
							case 01:r_ss01_The_Orders_Manager_selects_the_order_to_remove[]
							case 02:r_ss02_The_system_searches_the_order_to_remove_from_the_list_of_orders[]
							case 03:r_ss03_The_system_cancels_the_order[]
							case 04:r_validates_that [the_order_has_been_cancelled, CANCELORDERS_SAF_01]
							case 5:r_Cancel_Orders_postconditions[]
						endswitch
					case CANCELORDERS_SAF_01:
						switch($s)
							case 01:r_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_cancel_orders_specific_alternative_flow_01_postconditions[]
						endswitch 
					case CANCELORDERS_GAF_02:
						switch($s)
							case 01:r_gaf02_s01_The_system_cancels_the_transaction[]
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
					r_exec_one_step[currStep,currFlow] 
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
					r_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_cancel_orders_global_alternative_flow_02 =
			if(currFlow = CANCELORDERS_GAF_02) then
				seq
					r_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		

		// initialization of rules about launching of alternative and conditional flows
		rule r_init_cancel_orders( $uc in UseCase) =
			jump($uc, CANCELORDERS_BASIC, 04, 01) := <<r_cancel_orders_specific_alternative_flow_01>>
				
				
				
