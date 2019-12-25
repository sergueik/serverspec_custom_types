package example;

import java.util.Arrays;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

// slightly modified example from
// http://www.java2s.com/Code/Java/Regular-Expressions/SimpleNegativeLookahead.htm
// to ignore nested comments (which in fact are not lexically  allowed anyway)
// and the intend to find and possibly preserve the
// "hints" embedded in comments in the fashion
// may be useful for generated code validation

public class LookaheadTest {

	public static void main(String args[]) throws Exception {
		String hintRegex = "(\\/\\*\\+([^*]|\n|\\*[^/])*\\*\\/)";
		String commentRegex = "\\/\\*(?!\\+)([^*]|\n|\\*[^/])*\\*\\/";

		Pattern hintPattern = Pattern.compile(hintRegex,
				Pattern.CASE_INSENSITIVE | Pattern.MULTILINE);
		Pattern commentPattern = Pattern.compile(commentRegex,
				Pattern.CASE_INSENSITIVE | Pattern.MULTILINE);

		List<String> candidates = Arrays.asList(
				new String[] { "a /* comment */", "a multiline /* comment \n test */",
						"one more multiline /* comment \n\n test */",
						"this is /* comment */ invalid syntax test */",
						"example of /*+ hint */ that isn't a comment",
						"this is /* comment /*+ with hint */ inside */",
						"this is /* comment /*+ with \nmulti\nline hint */\n inside */" });
		for (

		String candidate : candidates) {
			System.err.println("INPUT:" + candidate);
			String fixedCandidate = candidate;
			Matcher hintMatcher = hintPattern.matcher(candidate);
			String hintGroup = null;
			boolean found = false;
			while (hintMatcher.find()) {
				found = true;
				hintGroup = hintMatcher.group();
				System.err.println("HINT: MATCH:" + hintGroup);
				CharSequence hintToken = hintGroup;
				CharSequence hintReplacer = hintGroup
						.replace((CharSequence) "/*+", (CharSequence) "<<<")
						.replace((CharSequence) "*/", (CharSequence) ">>>");
				System.err.println("REPLACE: " + hintToken + " WITH: " + hintReplacer);
				fixedCandidate = fixedCandidate.replace(hintToken, hintReplacer);
			}
			if (!found) {
				System.err.println("HINT: NO MATCH");
			}
			System.err.println("FIXED INPUT:" + fixedCandidate);

			Matcher commentMatcher = commentPattern.matcher(fixedCandidate);
			String commentGroup = null;
			found = false;
			while (commentMatcher.find()) {
				found = true;
				commentGroup = commentMatcher.group();
				System.err.println("COMMENT: MATCH:" + commentGroup);
			}
			if (!found) {
				System.err.println("COMMENT: NO MATCH");
			}
		}
	}
}
