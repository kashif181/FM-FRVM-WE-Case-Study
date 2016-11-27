	module Add_Items
	import StandardLibrary
	import Online_Order_Application_Common
	export *
	
	
	signature:
	
	dynamic monitored the_product_has_been_added : Boolean
	dynamic monitored the_quantity_of_the_product_has_been_updated : Boolean
	dynamic monitored the_system_is_idle : Boolean
	dynamic monitored the_quantity_entered_isnt_negative : Boolean
	dynamic monitored the_quantity_of_the_product_has_not_been_updated : Boolean
	dynamic monitored the_product_has_not_been_added : Boolean
	dynamic monitored the_user_clickcancel : Boolean
	
	dynamic controlled the_system_updates_the_quantity_of_the_product : Boolean
	dynamic controlled the_system_displays_an_error_message : Boolean
	dynamic controlled the_system_cancels_the_transaction : Boolean
	dynamic controlled the_user_selects_the_item_to_add : Boolean
	dynamic controlled the_user_selects_the_quantity_of_item_to_add : Boolean
	
		
	
		

	definitions:
		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_ss01_The_user_selects_the_item_to_add =
			the_user_selects_the_item_to_add := true
			
		rule r_ss02_The_User_selects_the_quantity_of_item_to_add =
			the_user_selects_the_quantity_of_item_to_add := true
			
		rule r_ss04_The_system_updates_the_quantity_of_the_product =
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
		rule r_saf01_s01_The_system_displays_an_error_message =
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
					
		rule r_gaf02_s01_The_system_cancels_the_transaction =
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
		
		rule r_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case ADDITEMS_BASIC:
						switch($s) 
							case 01:r_ss01_The_user_selects_the_item_to_add[]
							case 02:r_ss02_The_User_selects_the_quantity_of_item_to_add[]
							case 03:r_validates_that [the_quantity_entered_isnt_negative, ADDITEMS_SAF_01]
							case 04:r_ss04_The_system_updates_the_quantity_of_the_product[]
							case 5:r_Add_Items_postconditions[]
						endswitch
					case ADDITEMS_SAF_01:
						switch($s)
							case 01:r_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_add_items_specific_alternative_flow_01_postconditions[]
						endswitch 
					case ADDITEMS_GAF_02:
						switch($s)
							case 01:r_gaf02_s01_The_system_cancels_the_transaction[]
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
					r_exec_one_step[currStep,currFlow] 
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
					r_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_add_items_global_alternative_flow_02 =
			if(currFlow = ADDITEMS_GAF_02) then
				seq
					r_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		

		// initialization of rules about launching of alternative and conditional flows
		rule r_init_add_items( $uc in UseCase) =
			jump($uc, ADDITEMS_BASIC, 03, 01) := <<r_add_items_specific_alternative_flow_01>>
				
				
				
