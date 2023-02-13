package capsule.exception;

import haxe.Exception;

class ProviderDoesNotExistException extends Exception {
	public function new(id:Identifier, ?reason:String, ?previous) {
		var message = 'No provider exists for this mapping: ${id.toString()}';
		if (reason != null) {
			message += ' ' + reason;
		}
		super(message, previous);
	}
}
