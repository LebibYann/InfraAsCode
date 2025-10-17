import {
  IsString,
  IsOptional,
  IsDateString,
  IsBoolean,
  IsISO8601,
  IsNotEmpty,
} from 'class-validator';

export class UpdateTaskDto {
  @IsString()
  @IsOptional()
  title?: string;

  @IsString()
  @IsOptional()
  content?: string;

  @IsDateString()
  @IsOptional()
  due_date?: string;

  @IsBoolean()
  @IsOptional()
  done?: boolean;

  @IsISO8601()
  @IsNotEmpty()
  request_timestamp: string;
}
