import java.io.*;

public class MergeAndSplit {

    public static void main(String[] args) throws Exception {
        if (args.length < 4) {
            System.out.println("Usage: java MergeAndSplit type src trg merged");
            return;
        }
        String type = args[0];
        String srcFile = args[1];
        String trgFile = args[2];
        String mergedFile = args[3];

        if (type.equals("merge")) {
            BufferedReader brSrc = new BufferedReader(new InputStreamReader(new FileInputStream(srcFile), "utf-8"));
            BufferedReader brTrg = new BufferedReader(new InputStreamReader(new FileInputStream(trgFile), "utf-8"));
            BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(mergedFile), "utf-8"));

            String src, trg;

            while ((src = brSrc.readLine()) != null) {
                trg = brTrg.readLine();
                bw.write(src + " ||| " + trg + "\n");
            }


            brSrc.close();
            brTrg.close();
            bw.close();
        } else if (type.equals("split")) {
            BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(mergedFile), "utf-8"));
            BufferedWriter bwSrc = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(srcFile), "utf-8"));
            BufferedWriter bwTrg = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(trgFile), "utf-8"));
            String line;
            while ((line = br.readLine()) != null) {
                String[] tokens = line.trim().split(" \\|\\|\\| ");
                bwSrc.write(tokens[0] + "\n");
                bwTrg.write(tokens[1] + "\n");
            }

            br.close();
            bwSrc.close();
            bwTrg.close();
        } else {
            System.out.println("Unrecognized type, which should be merge or split.");
        }

    }
}

