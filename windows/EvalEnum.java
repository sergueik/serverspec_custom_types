import java.util.Scanner;
import java.lang.Enum;
import java.lang.IllegalArgumentException;

public class EvalEnum {
	enum MyEnum {
		One(1), Two(2), Three(3);

		private int code;

		MyEnum(int code) {
			this.code = code;
		}

	}

	public static void main(String[] args) {
		String name = new Scanner(System.in).next("[a-zA-Z]+");
		System.out
				.println(String.format("%s in MyEnum? %b", name, isNameAccepted(name)));
		int num = new Scanner(System.in).nextInt();
		System.out.println(
				String.format("%d in TestEnum values? %b", num, isValuePresent(num)));
	}

	private static boolean isValuePresent(int number) {
		for (MyEnum item : MyEnum.values()) {
			if (item.code == number)
				return true;
		}
		return false;
	}

	private static boolean isNameAccepted(String data) {
		try {
			Enum.valueOf(MyEnum.class, data);
			return true;
		} catch (IllegalArgumentException e) {
			return false;
		}
	}
}
