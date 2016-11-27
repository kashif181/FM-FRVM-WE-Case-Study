module Online_Order_Application_Common

import StandardLibrary
export *
	
signature:

// domains 
   
    
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
	
// functions

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
 
    
definitions:
	
	domain InitialUseCase = {MAKEORDERS, ADDITEMS, CANCELORDERS, REGISTER, DELETEITEMS}
	
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

