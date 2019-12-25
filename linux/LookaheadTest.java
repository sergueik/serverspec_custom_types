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
		String regex = "\\/\\*(?!\\+)([^*]|\n|\\*[^/])*\\*\\/";

		Pattern pattern = Pattern.compile(regex,
				Pattern.CASE_INSENSITIVE | Pattern.MULTILINE);

		List<String> candidates = Arrays.asList( new String[] {
			"a /* comment */", "a multiline /* comment \n test */",
			"one more multiline /* comment \n\n test */",
			"this is /* comment */ invalid syntax test */",
			"example of /*+ hint */ that isn't a comment",
			"this is /* comment /*+ with hint */ inside */" });
		for (String candidate : candidates) {
			Matcher matcher = pattern.matcher(candidate);
			System.err.println("INPUT:" + candidate);
			String group = null;
			boolean found = false;
			while (matcher.find()) {
				found = true;
				group = matcher.group();
				System.err.println("MATCH:" + group);
			}
			if (!found){
				System.err.println("NO MATCH");
			}
		}
	}
}


