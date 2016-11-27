	module Register
	import StandardLibrary
	import Online_Order_Application_Common
	export *
	
	
	signature:
	
	dynamic monitored the_credential_are_correct : Boolean
	dynamic monitored the_quantity_of_the_product_has_not_been_updated : Boolean
	dynamic monitored login_page_is_visible : Boolean
	dynamic monitored the_product_has_not_been_added : Boolean
	dynamic monitored the_user_is_register : Boolean
	dynamic monitored the_user_clickcancel : Boolean
	
	dynamic controlled the_system_displays_an_error_message : Boolean
	dynamic controlled the_system_cancels_the_transaction : Boolean
	dynamic controlled the_user_enter_username_and_password_ : Boolean
	
		
	
		

	definitions:
		//basic flow 
		
		//rules that represent the steps of basic flow
		rule r_ss01_The_User_enter_username_and_password_ =
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
		rule r_saf01_s01_The_system_displays_an_error_message =
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
					
		rule r_gaf02_s01_The_system_cancels_the_transaction =
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
		
		rule r_exec_one_step ($s in Integer, $f in Flow) = 
			seq
				if (resume = true) then resume := false endif
				switch ($f)
					case REGISTER_BASIC:
						switch($s) 
							case 01:r_ss01_The_User_enter_username_and_password_[]
							case 02:r_validates_that [the_credential_are_correct,REGISTER_SAF_01]
							case 3:r_Register_postconditions[]
						endswitch
					case REGISTER_SAF_01:
						switch($s)
							case 01:r_saf01_s01_The_system_displays_an_error_message[]
							case 02:r_abort[]
							case 3:r_register_specific_alternative_flow_01_postconditions[]
						endswitch 
					case REGISTER_GAF_02:
						switch($s)
							case 01:r_gaf02_s01_The_system_cancels_the_transaction[]
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
					r_exec_one_step[currStep,currFlow] 
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
					r_exec_one_step[currStep,currFlow] 
				 	if (resume = false) then currStep := currStep + 1 endif
				endseq
		 	endif

		//main rule of global alternative flow 02
					
		rule r_register_global_alternative_flow_02 =
			if(currFlow = REGISTER_GAF_02) then
				seq
					r_exec_one_step[currStep,currFlow] 
				 	currStep := currStep + 1
				endseq
		 	endif
				
		

		// initialization of rules about launching of alternative and conditional flows
		rule r_init_register( $uc in UseCase) =
			jump($uc, REGISTER_BASIC, 02, 01) := <<r_register>>
				
				
				
