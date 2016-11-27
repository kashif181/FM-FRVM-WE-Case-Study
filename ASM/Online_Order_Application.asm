	asm Online_Order_Application
	
	import StandardLibrary	
	import Online_Order_Application_Common
	import Register
	import Make_Orders
	import Add_Items
	import Delete_Items
	import Cancel_Orders
	export *
	
	signature:


	definitions:
	
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
						case MAKEORDERS : r_make_orders[]
						case ADDITEMS : r_add_items[]
						case CANCELORDERS : r_cancel_orders[]
						case REGISTER : r_register[]
						case DELETEITEMS : r_delete_items[]
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
	
