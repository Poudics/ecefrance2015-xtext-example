package org.eclipsecon.expdsl.tests

import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.eclipsecon.expdsl.ExpressionsInjectorProvider
import org.eclipsecon.expdsl.expressions.ExpressionsModel
import org.eclipsecon.expdsl.expressions.ExpressionsPackage
import org.junit.Test
import org.junit.runner.RunWith

import static extension org.junit.Assert.*
import org.eclipsecon.expdsl.validation.ExpressionsValidator
import org.eclipse.emf.ecore.EObject

@RunWith(typeof(XtextRunner))
@InjectWith(typeof(ExpressionsInjectorProvider))
class ExpressionsValidatorTest {
	
	@Inject extension ParseHelper<ExpressionsModel>
	@Inject extension ValidationTestHelper
	
	@Test
	def void testForwardReference() {
		val input = '''
			int i = j
			int j = 10
		'''
		input.parse.assertError(
			// type of the element with error
			ExpressionsPackage.Literals.VARIABLE_REF,
			// error code
			ExpressionsValidator.FORWARD_REFERENCE,
			input.indexOf("j"), // offset of expected error
			1, 					// length of the region with error
			// expected error message
			"variable forward reference not allowed: 'j'"
		)
	}

	@Test
	def void testForwardReferenceInExpression() {
		'''int i = 1 j+i int j = 10'''.parse => [
			assertError(ExpressionsPackage::eINSTANCE.variableRef,
				ExpressionsValidator.FORWARD_REFERENCE,
				"variable forward reference not allowed: 'j'"
			)
			
			// check that's the only error
			1.assertEquals(validate.size)
		]
	}

	@Test
	def void testCorrectProgram() {
		'''
		int i = 0
		int j = i + 1
		bool b = i <= 0
		b
		string s = "this is b: " + b
		b && (j < i)
		"is A < b ? " + "A" < "b"
		'''.parse.assertNoErrors
	}

	@Test
	def void testUnresolvedVariable() {
		"foo + bar".parse.assertIssuesAsStrings(
			'''
			Couldn't resolve reference to Variable 'foo'.
			Couldn't resolve reference to Variable 'bar'.
			'''
		)
	}

	def private assertIssuesAsStrings(EObject o, CharSequence expected) {
		expected.toString.trim.assertEquals(
			o.validate.map[message].
			join(System.getProperty("line.separator")))
	}
	
}