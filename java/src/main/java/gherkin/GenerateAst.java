package gherkin;

import gherkin.ast.Feature;
import gherkin.deps.com.google.gson.Gson;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;

public class GenerateAst {
    public static void main(String[] args) throws IOException {
        Gson gson = new Gson();
        Parser<Feature> parser = new Parser<>(new AstBuilder());
        TokenMatcher matcher = new TokenMatcher();

        long startTime = System.currentTimeMillis();
        for (String fileName : args) {
            Reader in = new InputStreamReader(new FileInputStream(fileName), "UTF-8");
            try {
                Feature feature = parser.parse(in, matcher);
                Stdio.out.println(gson.toJson(feature));
            } catch (ParserException e) {
                Stdio.err.println(e.getMessage());
                System.exit(1);
            }
        }
        long endTime = System.currentTimeMillis();
        if(System.getenv("GHERKIN_PERF") != null) {
            Stdio.err.println(endTime - startTime);
        }
    }

}
